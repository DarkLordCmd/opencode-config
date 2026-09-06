---
name: write-comments
description: >
  Use this skill whenever asked to write, add, update, or review comments in code.
  Also trigger when the user mentions "self-documenting code" or claims "good code
  doesn't need comments." Use when documenting a function, module, or API, or when
  asked to improve comment quality in a codebase.
---

# How to Write Code Comments

## The "Self-Documenting Code" Myth

Good names tell you *what* the code does. Comments tell you *why* it exists, *what constraints* it operates under, *why this approach* was chosen over alternatives, and *what invariants* must hold. No matter how expressive the identifiers, these things cannot be inferred from reading the code alone.

Do not skip comments on the grounds that "the code is clear." Clear code and good comments are complementary, not substitutes.

## Why Write Comments

1. Comments capture **design decisions and intent** that code cannot express.
2. Comments are part of the abstraction — good interface docs let callers avoid reading the implementation.
3. Writing comments **early** exposes design problems before you invest in implementation.
4. Good comments dramatically reduce cognitive load for future maintainers.

## What Comments Should Describe

- **Non-obvious information**: the *why*, constraints, boundary conditions, side effects — things invisible from the code itself.
- **Precision matters**: a vague comment creates false confidence and is often worse than none. Be specific about what, under what conditions, and why.
- Comments should NOT repeat what the code already says.

## Comment Layers

### Interface comments — *what* and *why*, no implementation details

Cover: what the function/module does, preconditions, postconditions, side effects, error semantics, and units where relevant. Never reveal implementation details the caller doesn't need.

**Bad** (repeats code, vague):
```python
# processes user
def process_user(user):
```

**Good** (precise, captures non-obvious contract):
```python
# Validates and normalizes the user record before persistence.
# Raises ValueError if user.email is missing — callers must handle this
# before calling. Does NOT send a welcome email; that's the caller's job.
def process_user(user):
```

---

### Implementation comments — *how* and *why this approach*

Explain tricky logic, non-obvious algorithmic choices, and workarounds. The target reader already knows what the code does — explain why it's done this way.

**Bad** (states the obvious):
```python
i += 1  # increment i
```

**Good** (explains the non-obvious):
```python
# Skip the first byte — it's a UTF-8 BOM that the downstream XML parser chokes on.
data = raw[1:]
```

---

### Cross-module comments — design decisions that span boundaries

Document dependencies, shared invariants, and coupling that can't be localized to a single module. These often belong in a module-level docstring or an architecture note.

## Red Flags

| Signal | Problem |
|--------|---------|
| **Comment Repeats Code** | English translation of what the code already says — adds noise, drifts out of sync. Delete or rewrite to add meaning. |
| **Vague Comment** | Says something without saying anything ("handles errors", "processes data", "helper function"). Be specific or remove it. |
| **Impl Contaminates Interface** | Interface comment mentions internal data structures, algorithms, or implementation choices the caller doesn't need. Strip them out — they create unnecessary coupling. |

## Comments-First Approach

Write interface comments *before* writing the implementation — use them as a design tool. If you struggle to write a clear, precise comment for a function, the design itself likely has a problem. The difficulty of articulation is diagnostic.
