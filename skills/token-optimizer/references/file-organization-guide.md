# File Organization Guide for AI-Efficient Codebases

## Why File Size Matters

AI agents read entire files to understand context. Large files mean:
- More tokens consumed reading irrelevant code
- Higher chance of confusion from unrelated logic
- Slower responses and higher costs
- Less precise edits (more surrounding code to consider)

## Core Rules

1. **Max 150 lines per file** — split by responsibility if longer
2. **Single responsibility** — one concern per file
3. **Descriptive kebab-case names** — the filename guides the AI

## Naming Conventions

### File Names: Avoid vs Prefer

| Avoid | Prefer | Why |
|-------|--------|-----|
| `utils.ts` | `string-utils.ts`, `date-utils.ts` | AI knows which to read |
| `helpers.ts` | `date-formatting-helpers.ts` | Specific scope is clear |
| `api.ts` | `users-api.ts`, `products-api.ts` | One endpoint group per file |
| `index.ts` (with logic) | `user-authentication.ts` | Index should only re-export |
| `data.ts` | `product-catalog-data.ts` | Content is obvious from name |
| `types.ts` (500 lines) | `user-types.ts`, `order-types.ts` | Scoped type definitions |
| `constants.ts` | `api-endpoints.ts`, `error-codes.ts` | Grouped by domain |
| `validator.ts` | `email-validator.ts` | Explicit about what it validates |

### Naming Rules

- Always use **kebab-case**: `user-profile-api.ts`
- Be explicit about content: `email-validator.ts` > `validator.ts`
- Only use letters, numbers, hyphens, and underscores
- Suffix with domain: `-service`, `-utils`, `-types`, `-api`, `-hooks`

## Component Organization (Frontend)

| Avoid | Prefer |
|-------|--------|
| Component with logic + UI + styles | Separate hook + presentational component + styles |
| `UserProfile.tsx` (300 lines) | `use-user-profile.ts` + `user-profile-view.tsx` + `user-profile.css` |

## Recommended Project Structure

```
src/
├── components/          → UI components (one per file)
│   ├── button.tsx
│   └── modal.tsx
├── hooks/               → Custom hooks
│   ├── use-auth.ts
│   └── use-form.ts
├── services/            → Business logic
│   ├── user-service.ts
│   ├── order-service.ts
│   └── email-service.ts
├── utils/               → Pure utility functions
│   ├── string-utils.ts
│   ├── date-utils.ts
│   └── validation-utils.ts
├── types/               → Type definitions
│   ├── user-types.ts
│   └── order-types.ts
└── api/                 → API route handlers
    ├── users-api.ts
    └── products-api.ts
tests/                   → Mirror src/ structure
docs/                    → Project documentation
```

## When to Split a File

Split when any of these apply:
- File exceeds 150 lines
- File has more than one "section" separated by comments
- You find yourself scrolling to find things
- The file handles two unrelated domains (e.g., users AND products)
- Multiple developers frequently edit the same file (merge conflicts)

## When NOT to Split

- File is under 50 lines and cohesive
- Splitting would create files with only 5-10 lines
- The concepts are genuinely coupled (e.g., a type and its factory function)

## Real Impact

From our experiment with an 814-line e-commerce app:

| Metric | Monolithic (1 file) | Modular (9 files) |
|--------|--------------------|--------------------|
| Bug fix tokens | 49,466 | 40,447 (**-18.2%**) |
| Lines AI processed | 814 | 67 (**-92%**) |
| Navigation precision | Scan entire file | Go directly to target |

The modular version's files ranged from 35-146 lines each. The AI navigated by filename directly to `validation-utils.ts` (67 lines) instead of scanning 814 lines.

## Checklist

- [ ] No file exceeds 150 lines
- [ ] Every file has a single, clear responsibility
- [ ] File names describe their contents (no generic names)
- [ ] kebab-case naming throughout
- [ ] Project structure is documented in CLAUDE.md
