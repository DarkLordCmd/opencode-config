---
name: uv-audit
description: >
  Python dependency security auditor using uv. Use this skill whenever asked to
  audit dependencies, check for security vulnerabilities or CVEs, update packages,
  fix outdated dependencies, run pip-audit, or keep a Python project's pyproject.toml
  current and safe. Trigger proactively when the user mentions dependency hygiene,
  wants to harden their Python project, or asks anything about package versions,
  security issues, or dependency updates — even if they don't use the word "audit".
---

# UV Dependency Audit

You are a Python dependency security expert. Your job: audit a project's dependencies
for vulnerabilities and outdated packages, update them safely, verify nothing broke,
and produce a clear report. Work through these phases in order. Do not skip ahead.

---

## Phase 0: Prerequisites

```bash
which uv   # must be on PATH — stop and tell user to install uv if missing
```

Find `pyproject.toml` — check the current directory first, then walk up. If not found,
stop and tell the user: "No pyproject.toml found. Run `uv init` to create one, then
re-run the audit."

Read `pyproject.toml` to catalogue every declared package across all groups:
- `[project].dependencies`
- `[project.optional-dependencies.*]`
- `[dependency-groups.*]` and/or `[tool.uv.dev-dependencies]`

---

## Phase 1: Audit (read-only — no changes yet)

### Sync the lock file

```bash
uv lock --quiet
```

This resolves dependencies without installing anything. If the lock file is stale or
missing, this regenerates it.

### Security scan

```bash
uv audit --preview-features audit
```

`uv audit` reads directly from the uv lock file — no Python version mismatch issues.
Parse the output to record for each vulnerability:
- package name, installed version
- vulnerability ID (CVE/GHSA), description
- fix version

If uv is older than 0.5 and `uv audit` is not available, fall back to:
```bash
uv export --format requirements-txt --no-hashes --quiet -o /tmp/uv-audit-reqs.txt
uvx pip-audit -r /tmp/uv-audit-reqs.txt
```

### Outdated package check

```bash
uv sync --no-install-project --quiet
uv pip list --outdated --format json
```

This compares installed versions against the latest on PyPI.

**If `uv sync --no-install-project` fails** (e.g. an old package is incompatible with
the current Python version — a common signal that packages urgently need updating):
- Note the failure and the specific package causing it in the report
- Skip the `uv pip list --outdated` step (environment is not installable)
- Proceed directly to Phase 3 — the update will fix the compatibility issue
- Come back to Phase 4 (test verification) after updating

### Summarise findings to the user

Before changing anything, print a quick console summary:

```
=== Audit findings (pre-update) ===
Security vulnerabilities : X packages
Outdated packages        : Y packages
Environment status       : installable / BROKEN (reason)
```

List each vulnerability with its ID so the user sees what's at stake.

---

## Phase 2: Establish a test baseline

Changes must not break the project. Establish a green baseline before touching anything.
**Skip this phase if the environment was not installable in Phase 1** — you cannot run
tests against a broken environment. Note the skip in the report and proceed to Phase 3;
run tests in Phase 4 after updating.

### Look for an existing test suite

Search for:
- `tests/` or `test/` directory containing `test_*.py` or `*_test.py` files
- `pytest.ini`, `conftest.py`, or `[tool.pytest.ini_options]` in `pyproject.toml`

If found, run it:

```bash
uv run --no-project pytest -v --tb=short
```

(`--no-project` skips the project editable-install step, which fails for packages with
no source directory and is unnecessary for running tests against already-installed deps.)

**If the baseline fails:** diagnose the reason before deciding how to proceed.

- **Failure is a code bug** (test logic, assertion error, missing fixture): stop, report
  the failures, and ask the user to fix them before proceeding. Do not update packages
  when tests are already broken for reasons unrelated to package versions.

- **Failure is a package compatibility error** (import error, AttributeError on a
  standard-library type, `distutils` missing, etc.): this means the old pinned package
  is broken on the current Python. Proceed with the update — fixing the pinned version
  is the correct action. Note the baseline failure and its cause in the report.

### If no test suite exists

Create one that proves the environment is importable. This is a safety net, not a
replacement for real tests.

Read `scripts/test_imports_template.py` from this skill's directory. Use it as the
base for `tests/test_imports.py`: fill in the `PACKAGES` list with the actual import
names derived from `pyproject.toml` (apply the `_KNOWN_IMPORT_NAMES` mappings in the
template; fall back to `pkg.lower().replace("-", "_")` for anything else). Skip
CLI-only tools with no importable API (`black`, `ruff`, `mypy`, `pytest` itself, etc.).

Create `tests/__init__.py` (empty) alongside it.

Ensure `pytest` is a dev dependency:

```bash
uv add --dev pytest --no-sync
```

Run the generated suite and confirm it passes before continuing.

---

## Phase 3: Update dependencies

### Strategy

| Situation | Action |
|-----------|--------|
| Security vulnerability | Update to the minimum fixed version or latest, whichever is higher |
| Outdated (no CVE) | Update to latest |
| Conflict | Let uv's resolver find the highest compatible version; record what was constrained |

The goal is **actual latest versions**, not just "latest within existing constraints."
`uv lock --upgrade` only refreshes within the bounds already declared in `pyproject.toml`
— if a dep is pinned `requests>=2,<3`, it stays on 2.x. To reach the true latest, strip
the upper-bound constraints first.

### Strip upper-bound constraints and upgrade

Run the bundled script from the project directory (substitute the actual skill path):

```bash
python <skill_dir>/scripts/strip_upper_bounds.py
```

This removes `<X.Y.Z` caps from dependency sections only — `requires-python`,
build-system `requires`, and all other fields are left untouched. The logic has been
tested against edge cases; don't rewrite it inline.

Then upgrade all packages within the now-unconstrained specs:

```bash
uv lock --upgrade
uv sync --no-install-project --quiet
```

uv's resolver will find the highest mutually compatible versions for all packages.

### Handling conflicts

If `uv lock --upgrade` fails with a resolution error:

1. Read uv's error output — it names the conflicting packages.
2. For each conflict, restore a constraint that allows resolution. Start with the latest
   minor version and work down until it resolves:
   ```bash
   uv add "package>=X.Y,<X.Z" --no-sync
   ```
3. Re-run `uv lock && uv sync --no-install-project`.
4. Keep a list of every package pinned below latest due to a conflict — this goes in
   the report.

### Record what changed

```bash
git diff uv.lock   # if in a git repo — shows exactly what moved
```

---

## Phase 4: Verify

```bash
uv run --no-project pytest -v --tb=short 2>&1 | tee /tmp/post-update-test-results.txt
```

**If tests pass:** proceed to Phase 5.

**If tests fail:**
1. Show the exact failure output.
2. Cross-reference failing tests with the packages that changed — name the most likely
   culprit(s).
3. Do NOT revert automatically. Tell the user what broke and offer two paths:
   - Revert the offending package: `uv add "package==<previous-version>"`
   - Revert everything: `git checkout pyproject.toml uv.lock && uv sync`
4. Wait for the user to decide.

---

## Phase 5: Report

### Console summary

```
=== UV Dependency Audit — {date} ===

Security fixes   : X applied  (Y remaining / unfixable)
Package updates  : X applied  (Y conflicts resolved)
Test suite       : PASS — N tests  |  FAIL — N failures

Security fixes applied:
  requests  2.28.0 → 2.32.3   CVE-2024-35195
  ...

Updates applied:
  numpy     1.24.0 → 2.1.0
  ...

Conflicts (pinned to highest compatible):
  somelib   pinned to 3.1.2   (blocked by other-package's upper bound)
  ...
```

### Markdown report

Write `audit_report_{YYYY-MM-DD}.md` to the project root:

```markdown
# Dependency Audit Report — {date}

## Summary

| Category | Found | Resolved |
|----------|-------|----------|
| Security vulnerabilities | X | Y |
| Outdated packages | X | Y |
| Dependency conflicts | X | X (all) |
| Tests | N total | N passed / N failed |

---

## Security Vulnerabilities

| Package | Before | After | ID | Description |
|---------|--------|-------|----|-------------|

---

## Package Updates

| Package | Before | After | Notes |
|---------|--------|-------|-------|

---

## Dependency Conflicts

| Package | Pinned To | Blocked By | Notes |
|---------|-----------|------------|-------|

---

## Test Results

**Status**: PASS / FAIL

<details>
<summary>Test output</summary>

```
{paste pytest -v output here}
```

</details>

---

## Remaining Issues

{Anything that could not be resolved automatically:
- packages with no fix available for a known CVE
- packages pinned below latest due to conflicts
- test failures that need manual intervention}
```

---

## Edge cases to handle gracefully

- **`uv audit` finds nothing**: report "No known vulnerabilities found" — don't skip the section.
- **Package has no PyPI entry** (private/VCS dep): skip it in the outdated check, note it.
- **Multiple `pyproject.toml`** (monorepo): audit each one separately; ask the user which
  to start with if ambiguous.
- **No internet access**: `uv audit` and `uv pip list --outdated` will fail; report this
  clearly rather than silently producing empty results.
- **Upper-bound stripping**: handled by the bundled `scripts/strip_upper_bounds.py` — don't rewrite the logic inline.
