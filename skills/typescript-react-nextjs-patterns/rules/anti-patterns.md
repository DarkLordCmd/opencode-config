# Anti-patterns

> **Scope**: Common mistakes with symptoms, root causes, consequences, and fixes  
> **Consult when**: Reviewing code, refactoring, identifying recurring problems  
> **See also**: → `debugging-checklists.md`, → `code-review-rules.md`, → `playbooks/`

---

## 1. `any` Infection [HARD RULE violation]

**Symptom**: No type errors anywhere, but runtime crashes on property access.  
**Root cause**: One `any` disables checking for everything downstream.  
**Consequence**: Type system becomes decorative. Bugs surface only in production.

```ts
// ❌ any spreads silently through the call chain
function getConfig(): any { return JSON.parse(rawConfig) }
const port = getConfig().port          // any
const url = `http://localhost:${port}`  // any
fetch(url)                              // any — entire chain untyped

// ✅ unknown + validation — one line fixes the whole chain
function getConfig(): unknown { return JSON.parse(rawConfig) }
const config = configSchema.parse(getConfig())
const port = config.port  // number — typed from here forward
```

**How to find it**: Search codebase for `: any`, `as any`, `<any>`. Each occurrence needs justification or replacement.

---

## 2. Baseless Type Assertions [HARD RULE violation]

**Symptom**: Code compiles but crashes at runtime with "Cannot read properties of undefined".  
**Root cause**: `as Type` tells TypeScript "trust me" — but the data doesn't match.  
**Consequence**: Silent runtime failures. The type system explicitly warned you, and `as` overrode it.

```ts
// ❌ API response might not match User at all
const user = (await res.json()) as User
console.log(user.profile.avatar)  // 💥 if profile is undefined

// ✅ Validate — crash is caught early with a clear message
const user = userSchema.parse(await res.json())
// If shape doesn't match → ZodError with field-level details
```

**When `as` IS acceptable** (rare):
- Narrowing after a type guard that TypeScript can't follow (document with comment)
- `querySelector` results you control: `document.querySelector('#email') as HTMLInputElement | null` — the selector's element type is knowledge TS doesn't have. (A properly typed `useRef<HTMLInputElement>(null)` needs no cast after a null check.)
- Test mocks where partial objects are intentional

---

## 3. Enum Overuse [DEFAULT violation]

**Symptom**: Runtime enum objects in the bundle, friction with modern toolchains.  
**Root cause**: `enum` emits runtime JavaScript and is non-erasable TypeScript-specific syntax.  
**Consequence**: Bundle bloat, banned under `erasableSyntaxOnly` (TS 5.8+) and Node.js type stripping, can't be used in `.js` files.

```ts
// ❌ enum — emits a runtime object, breaks tree-shaking, non-erasable syntax
enum Status { Idle, Loading, Success, Error }
enum Color { Red = 'RED', Blue = 'BLUE' }
// Note: since TS 5.0 all enums are union enums — `const s: Status = 999` is a
// compile error now, so out-of-range values are NOT the reason to avoid enums

// ✅ Union literal — zero runtime, exhaustive checking works
type Status = 'idle' | 'loading' | 'success' | 'error'

// ✅ When runtime values needed — as const object
const Color = { Red: 'RED', Blue: 'BLUE' } as const
type Color = (typeof Color)[keyof typeof Color]  // 'RED' | 'BLUE'
```

---

## 4. Excessive Optionals [DEFAULT violation]

**Symptom**: Component is littered with `?.` and `?? fallback` on props that are always provided.  
**Root cause**: Developer marked props optional "just in case" or copied from a `Partial<T>` type.  
**Consequence**: Null checks spread through the entire component. Bugs when a truly-needed prop is accidentally omitted — no compile error.

```tsx
// ❌ 6 optional props, but all are always passed
interface OrderCardProps {
  order?: Order
  onEdit?: () => void
  onDelete?: () => void
  formatDate?: (d: Date) => string
  currency?: string
  showActions?: boolean
}

// ✅ Only mark what's truly optional
interface OrderCardProps {
  order: Order
  onEdit: () => void
  onDelete: () => void
  currency?: string         // genuinely optional — defaults to 'USD'
  showActions?: boolean     // genuinely optional — defaults to true
}
```

**Rule of thumb**: If removing `?` causes compile errors at every call site because the prop IS always passed — it shouldn't be optional.

---

## 5. Non-null Assertion (`!`) Abuse [HARD RULE violation]

**Symptom**: Random `TypeError: Cannot read properties of null` in production.  
**Root cause**: `!` tells TypeScript "this is never null" — but it might be.  
**Consequence**: Bypasses the exact safety net TypeScript provides.

```ts
// ❌ Crashes if element doesn't exist (e.g., SSR, race condition)
const el = document.getElementById('root')!
el.innerHTML = 'Hello'

// ✅ Explicit error with context
const el = document.getElementById('root')
if (!el) throw new Error('Root element not found — check index.html')
el.innerHTML = 'Hello'

// ✅ In React — useRef pattern
const inputRef = useRef<HTMLInputElement>(null)
const focusInput = () => {
  inputRef.current?.focus()  // safe — no crash if unmounted
}
```

---

## 6. Duplicated Source of Truth [HARD RULE violation]

**Symptom**: UI shows stale data after mutation. Two parts of the UI show different values for the same entity.  
**Root cause**: Server data copied into `useState` — the copy gets out of sync with the cache.  
**Consequence**: Stale data, race conditions, users seeing inconsistent state.

```tsx
// ❌ Copying query data into local state
function UserSettings() {
  const { data: user } = useQuery(userQueryOptions(id))
  const [name, setName] = useState(user?.name ?? '')  // stale if user refetches

  // After mutation, query cache updates but `name` still holds old value
}

// ✅ Query owns the data — local state only for in-progress edits
function UserSettings() {
  const { data: user } = useQuery(userQueryOptions(id))
  const [editName, setEditName] = useState<string | null>(null)  // null = not editing

  const displayName = editName ?? user?.name ?? ''
  // When editing: local state. When not: query data.
  // After save: setEditName(null) → falls back to fresh query data
}
```

---

## 7. `"use client"` Too High [DEFAULT violation]

**Symptom**: Entire page is client-rendered. Large JavaScript bundle. Slow TTFB.  
**Root cause**: Adding `"use client"` to the page component because one child needs interactivity.  
**Consequence**: All children become client components. Server rendering benefits lost.

```tsx
// ❌ Entire page is now client — 50KB+ unnecessary JS
'use client'
export default function ProductPage() {
  const [quantity, setQuantity] = useState(1)  // only this needs client
  const product = useProduct(id)               // could be server fetch
  return (
    <article>
      <h1>{product.name}</h1>        {/* could be server-rendered */}
      <p>{product.description}</p>    {/* could be server-rendered */}
      <QuantityPicker value={quantity} onChange={setQuantity} />
    </article>
  )
}

// ✅ Only the interactive part is client
// page.tsx (Server Component — default)
export default async function ProductPage({ params }: PageProps) {
  const { id } = await params
  const product = await getProduct(id)
  return (
    <article>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <QuantityPicker productId={id} />  {/* client island */}
    </article>
  )
}

// QuantityPicker.tsx
'use client'
function QuantityPicker({ productId }: { productId: string }) {
  const [quantity, setQuantity] = useState(1)
  return <input type="number" value={quantity} onChange={e => setQuantity(+e.target.value)} />
}
```

---

## 8. Unstable Effect Dependencies [HARD RULE violation]

**Symptom**: Component re-renders infinitely. Network tab shows the same request firing repeatedly.  
**Root cause**: Object or array created during render → new reference each render → effect re-runs.  
**Consequence**: Infinite loop, excessive API calls, browser tab freezes.

```ts
// ❌ filters is a new object every render → effect re-runs every render
// (add a setState inside and it becomes an infinite loop)
function OrderList({ page, sort }: { page: number; sort: string }) {
  const filters = { page, sort }
  useEffect(() => {
    fetchOrders(filters)
  }, [filters])
}

// ✅ Destructure to primitives
useEffect(() => {
  fetchOrders({ page, sort })
}, [page, sort])  // primitives are compared by value
```

See → `playbooks/effect-dependency-bugs.md` for the full diagnosis playbook.

---

## 9. Cargo-cult Memoization [DEFAULT violation]

**Symptom**: `useMemo`, `useCallback`, `React.memo` everywhere but no measurable performance improvement.  
**Root cause**: "Memoize everything" advice without understanding when it helps.  
**Consequence**: Added complexity, harder refactoring, false sense of optimization.

```tsx
// ❌ Memoizing trivial computations
const len = useMemo(() => items.length, [items])

// ❌ useCallback without a memoized consumer
const handleClick = useCallback(() => doThing(), [])
<button onClick={handleClick} />  // button is NOT memoized — callback stability doesn't matter

// ❌ React.memo on component receiving new objects every render
const MemoCard = React.memo(Card)
<MemoCard style={{ color: 'red' }} />  // new object → memo is useless
```

**When memoization IS justified**: See → `performance-and-accessibility.md` (list rendering optimization).

---

## 10. Missing Runtime Validation [HARD RULE violation]

**Symptom**: App crashes on unexpected API response shape. Form submits invalid data.  
**Root cause**: Trusting TypeScript types for data that comes from outside the application.  
**Consequence**: Runtime crash, data corruption, security vulnerabilities.

**Trust boundaries that MUST be validated**:
- API responses (`fetch`, GraphQL, WebSocket)
- URL parameters (`params`, `searchParams`)
- Form data (`FormData`)
- localStorage / sessionStorage
- postMessage from iframes
- Third-party SDK callbacks

---

## 11. Type/Runtime Confusion [HARD RULE violation]

**Symptom**: Compile errors like "'User' only refers to a type, but is being used as a value" — or, in untyped JS, runtime checks that silently never match.  
**Root cause**: Thinking TypeScript types exist at runtime (they're erased during compilation).

```ts
// ❌ TS rejects both at compile time ('User' is a type, not a value);
//    in plain JS the first would silently never match
if (typeof user === 'User') { ... }
if (user instanceof User) { ... }  // User is an interface, not a class

// ✅ Runtime check on actual fields
function isUser(v: unknown): v is User {
  return typeof v === 'object' && v !== null && 'name' in v && 'email' in v
}

// ✅ Or Zod for structured validation
const result = userSchema.safeParse(data)
if (result.success) { /* result.data is User */ }
```

---

## 12. Server-only Leaks [HARD RULE violation]

**Symptom**: Database connection string visible in browser dev tools. Bundle size spike.  
**Root cause**: Importing server-only code (database, API keys, secrets) in a client component.  
**Consequence**: Security vulnerability (secrets in browser), massive bundle bloat.

```tsx
// ❌ db import in client component — secrets shipped to browser
'use client'
import { db } from '@/lib/db'

// ✅ Guard sensitive modules
// lib/db.ts
import 'server-only'  // compile error if imported from client component
export const db = new PrismaClient()
```

**How to find it**: Search for `import 'server-only'` — if your DB/auth/secrets modules DON'T have it, add it.

---

## 13. Legacy React APIs in React 19 Code [DEFAULT violation]

**Symptom**: New code in a React 19 project still uses pre-19 wrappers.  
**Root cause**: Snippets and habits (and training data) frozen on React 18.  
**Consequence**: Deprecation warnings, pointless indirection, harder future upgrades.

| Legacy (React 18) | React 19+ |
|-------------------|-----------|
| `React.forwardRef((props, ref) => …)` | `ref` is a regular prop |
| `<Ctx.Provider value={v}>` | `<Ctx value={v}>` |
| `useFormState` (react-dom) | `useActionState` (react) |
| `useContext` for a conditional read | `use(Ctx)` — callable inside conditions |
| Reading `element.ref` | Removed — refs travel as props |

**Check the React version first** — in an 18 codebase the left column is correct, not legacy.

---

## Review Checklist

- [ ] Search for `any` — each needs justification or replacement
- [ ] Search for `as ` — each assertion needs documented safety reason
- [ ] Search for `enum` — replace with union + `as const`
- [ ] Search for `!` — must have preceding null check
- [ ] External data validated at every boundary (API, URL, form, storage)
- [ ] No `useState` holding a copy of query/server data
- [ ] `"use client"` at the deepest possible level
- [ ] `useEffect` dependencies are primitives or stable references
- [ ] No memoization without measured performance need
- [ ] Server-only modules protected with `import 'server-only'`
