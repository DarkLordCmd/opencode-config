# Context Management Guide

## The Problem

Token waste primarily comes from accumulated irrelevant context, not individual operations. A long conversation carries all prior context forward, even when you've switched tasks entirely.

## Session Hygiene

### Commands Reference

| Command | When to Use | What It Does |
|---------|-------------|--------------|
| `/clear` | Switching tasks, after major corrections | Resets context completely |
| `/compact` | Long session (>50 exchanges) | Compresses history, keeps essentials |
| `/context` | Diagnosing costs, before/after optimization | Shows token consumption breakdown |
| `/cost` | Anytime you want to see current spend | Shows current session cost; configure the statusline for continuous display |

### When to Clear

- After completing a feature or fixing a bug
- When you've corrected Claude 2+ times on the same thing
- When switching between unrelated parts of the codebase
- When responses feel slow or unfocused

### When to Compact

- Conversation is long but you're still on the same task
- You need prior context but responses are slowing down
- `/clear` would lose important context you still need

## Lazy Loading of Context

### The Principle

Claude doesn't need all information upfront. It needs to know **when and where** to load information.

### Implementation

Instead of putting everything in CLAUDE.md:

```markdown
# Bad: 400 lines of auth documentation in CLAUDE.md

## Authentication
OAuth2 flow: first redirect to /auth/login which calls...
[...200 lines of implementation details...]
```

Use triggers that reference detailed docs:

```markdown
# Good: 2 lines in CLAUDE.md, details in separate file

## Authentication
For auth implementation details, see docs/auth-guide.md
```

### Real Results

One project achieved **54% reduction** in initial tokens:
- Before: 7,584 tokens loaded on every conversation start
- After: 3,434 tokens — only triggers and references
- Details loaded on demand when the AI actually needs them

### What Goes in CLAUDE.md vs Referenced Files

| In CLAUDE.md | In Referenced Files |
|-------------|-------------------|
| Tech stack (1-2 lines) | Framework-specific patterns |
| Project structure | Detailed architecture docs |
| Key commands | CI/CD pipeline details |
| Naming conventions | Style guide edge cases |
| "See docs/X for Y" triggers | Full implementation guides |

## Subagent Strategy

### Why Subagents Save Tokens

When you run a verbose operation (tests, builds, searches) in the main conversation, all that output stays in your context window forever. With subagents, the verbose output lives in the subagent's context — only a summary returns.

### Best Candidates for Subagents

| Task | Why Subagent Helps |
|------|--------------------|
| Running test suites | Test output can be 100+ lines |
| Broad codebase searches | Multiple file reads stay contained |
| Build/compilation | Build logs don't pollute main context |
| Log analysis | Large log files stay in subagent |
| Dependency audits | Package listings stay contained |

### How to Use

Ask Claude to delegate: "Use a subagent to run the tests and summarize results" or use the Task tool directly in your workflow.

## MCP Management

### Limits

- **Max 10 active MCPs** at a time
- **Max 80 total tools** across all MCPs
- Each MCP adds token overhead even when unused (tool descriptions are sent every turn)

### Optimization

1. Audit which MCPs are currently active: check `.claude/settings.json`
2. Disable MCPs not needed for the current task
3. Group related tools — prefer one MCP with 5 tools over 5 MCPs with 1 tool each
4. Re-enable MCPs only when switching to tasks that need them

## Model Selection Strategy

### Cost Comparison

| Model | Relative Cost | Best For |
|-------|--------------|----------|
| Haiku | 1x | Simple tasks, tests, quick searches |
| Sonnet | ~5x | Most daily work, code generation |
| Opus | ~18x | Complex architecture, deep reasoning |

### Decision Framework

- **Default to Sonnet** for everyday coding tasks
- **Use Haiku** when the task is straightforward (simple edits, running tests, basic searches)
- **Escalate to Opus** only for genuinely complex problems (architectural decisions, intricate debugging, multi-system analysis)

### Impact

Switching from Opus to Sonnet for routine tasks can reduce costs by ~70%. Using Haiku for simple operations saves up to 94% compared to Opus.

## Checklist

- [ ] Use `/clear` between unrelated tasks
- [ ] Use `/compact` in long conversations
- [ ] Move detailed docs from CLAUDE.md to referenced files
- [ ] Delegate verbose operations to subagents
- [ ] Keep active MCPs under 10
- [ ] Default to Sonnet, use Haiku for simple tasks
