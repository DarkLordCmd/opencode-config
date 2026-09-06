# Optimized CLAUDE.md Template

Use this template as a starting point. Keep your CLAUDE.md under 500 lines — essentials only.

````markdown
# Project Name

Brief one-line description of the project.

## Tech Stack

- Language: TypeScript
- Framework: Next.js 14 (App Router)
- Database: PostgreSQL with Prisma ORM
- Testing: Vitest

## Project Structure

src/           → application code
tests/         → unit tests
docs/          → documentation
components/    → UI components
services/      → business logic
utils/         → specific utilities (string-utils, date-utils, etc.)

## Key Conventions

- Files: kebab-case, max 150 lines, single responsibility
- Tests: colocated in __tests__/ folders
- Imports: absolute paths from @/

## Commands

- `npm run dev` — start dev server
- `npm test` — run tests
- `npm run lint` — lint code

## Important Patterns

- All API routes in src/app/api/
- Shared types in src/types/
- Business logic in src/services/, never in components
````

## What Makes This Template Effective

1. **Concise** — only essentials, no verbose documentation
2. **Specific** — "PostgreSQL with Prisma" not just "database"
3. **Structured** — tells the AI where things live
4. **Actionable** — includes commands the AI can run
5. **Trigger-based** — references detailed docs instead of inlining them

## Common Mistakes to Avoid

- Don't paste entire API documentation into CLAUDE.md
- Don't list every file in the project — focus on structure
- Don't include step-by-step tutorials — reference them instead
- Don't exceed 500 lines — diminishing returns after that
