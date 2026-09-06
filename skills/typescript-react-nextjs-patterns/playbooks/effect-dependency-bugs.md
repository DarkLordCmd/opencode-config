# Playbook: useEffect Dependency Bugs

> **Scope**: Infinite loops, stale closures, missing cleanups, effects that shouldn't be effects  
> **Consult when**: Component keeps re-rendering, data is stale, memory leaks, "too many re-renders"  
> **See also**: → `rules/performance-and-accessibility.md`, → `rules/anti-patterns.md`

---

## Diagnosis: Which Bug Is It?

| Symptom | Likely cause | Section |
|---------|-------------|---------|
| Infinite re-render loop | Unstable dependency | → Object/Array Dependencies |
| Effect re-runs whenever a callback prop changes | Function dependency | → Function Dependencies |
| State value always initial | Stale closure | → Stale Closure |
| Memory leak / duplicate listeners | Missing cleanup | → Missing Cleanup |
| Effect runs twice on mount (dev only) | StrictMode remount cycle | → Effect Runs Twice |
| Effect runs on wrong trigger | Should be event handler | → Effect vs Handler |

---

## Object/Array Dependencies → Infinite Loop

**Root cause**: Object or array created during render → new reference every time → effect re-runs → state update → re-render → new object → ∞

```ts
// ❌ filters is a new object every render
function UserList({ page, sort }: { page: number; sort: string }) {
  const filters = { page, sort }  // new object every render

  useEffect(() => {
    fetchUsers(filters)
  }, [filters])  // reference changes every render → infinite loop
}

// ✅ Fix 1: Destructure to primitives
useEffect(() => {
  fetchUsers({ page, sort })
}, [page, sort])

// ✅ Fix 2: Stabilize with useMemo (when object is complex)
const filters = useMemo(() => ({ page, sort, ...otherStuff }), [page, sort])
useEffect(() => { fetchUsers(filters) }, [filters])
```

**Tradeoff**: Fix 1 is simpler and preferred. Fix 2 is for objects with many fields where destructuring is unwieldy. (React Compiler auto-memoizes render-created objects, which incidentally stabilizes deps — but don't rely on it for correctness.)

### Function Dependencies

Callback props and inline functions are new references every render too — at least as common a loop source as objects.

```ts
// ❌ onMessage gets a new identity on every parent render → re-subscribes constantly
function Chat({ roomId, onMessage }: ChatProps) {
  useEffect(() => {
    const socket = connect(roomId)
    socket.on('message', onMessage)
    return () => socket.close()
  }, [roomId, onMessage])
}

// ✅ React 19.2+: useEffectEvent — always calls the latest onMessage
// without making it a dependency
function Chat({ roomId, onMessage }: ChatProps) {
  const handleMessage = useEffectEvent(onMessage)

  useEffect(() => {
    const socket = connect(roomId)
    socket.on('message', (msg: Message) => handleMessage(msg))
    return () => socket.close()
  }, [roomId])  // effect events are never listed as deps

  return null
}

// ✅ Pre-19.2: stabilize at the source — wrap the callback in useCallback
// where it's defined (the parent), not where it's consumed
```

---

## Stale Closure

**Root cause**: Callback inside effect captures the state value at creation time, not the current value.

```ts
// ❌ count is captured at the time the effect was created
function Counter() {
  const [count, setCount] = useState(0)

  useEffect(() => {
    const id = setInterval(() => {
      console.log(count)      // always 0
      setCount(count + 1)     // always sets to 1
    }, 1000)
    return () => clearInterval(id)
  }, [])  // empty deps → closure captures initial count

  return <span>{count}</span>
}

// ✅ Fix: Use updater function
useEffect(() => {
  const id = setInterval(() => {
    setCount(prev => prev + 1)  // always reads latest
  }, 1000)
  return () => clearInterval(id)
}, [])
```

**When updater isn't enough** (need to read current state/props for logic):

```ts
// ✅ React 19.2+: useEffectEvent — the canonical stale-closure fix.
// Reads the latest values, never re-triggers the effect.
import { useEffectEvent } from 'react'

function Counter() {
  const [count, setCount] = useState(0)

  const onTick = useEffectEvent(() => {
    if (count >= 10) return       // always sees the latest count
    setCount(prev => prev + 1)
  })

  useEffect(() => {
    const id = setInterval(() => onTick(), 1000)
    return () => clearInterval(id)
  }, [])  // never list effect events as deps; call them only from inside effects

  return <span>{count}</span>
}
```

```ts
// ✅ Pre-19.2 fallback: sync a ref INSIDE an effect.
// Never write `ref.current = count` in the render body — render-phase ref
// mutation is impure, unsafe under concurrent rendering, and rejected by
// React Compiler.
const countRef = useRef(count)
useEffect(() => { countRef.current = count }, [count])

useEffect(() => {
  const id = setInterval(() => {
    if (countRef.current >= 10) { /* stop logic */ }
    setCount(prev => prev + 1)
  }, 1000)
  return () => clearInterval(id)
}, [])
```

---

## Missing Cleanup

**Root cause**: Event listener, timer, or subscription created but never removed.

```ts
// ❌ Listener never removed — leaks on unmount, duplicates on remount
// (StrictMode's dev double-invocation exposes exactly this)
useEffect(() => {
  window.addEventListener('resize', handleResize)
}, [])

// ❌ Timer never cleared
useEffect(() => {
  const id = setInterval(tick, 1000)
}, [])

// ✅ Always return cleanup
useEffect(() => {
  window.addEventListener('resize', handleResize)
  return () => window.removeEventListener('resize', handleResize)
}, [])

useEffect(() => {
  const id = setInterval(tick, 1000)
  return () => clearInterval(id)
}, [])
```

### Cleanup checklist:

- `addEventListener` → `removeEventListener`
- `setInterval` / `setTimeout` → `clearInterval` / `clearTimeout`
- `WebSocket` / `EventSource` → `.close()`
- `AbortController` → `.abort()` (for fetch)
- Subscription (RxJS, Firebase) → `.unsubscribe()` / cleanup callback

---

## Effect Runs Twice (StrictMode)

**Symptom**: "Why does my effect run twice on mount?" — development only, React 18+ under `<StrictMode>`.

React deliberately runs mount → unmount → remount in dev to surface missing cleanups. This is not a bug, and production runs the effect once.

```ts
// ❌ Suppressing the double-run hides the real problem
const didRun = useRef(false)
useEffect(() => {
  if (didRun.current) return
  didRun.current = true
  connect()
}, [])

// ✅ Make cleanup mirror setup — then the dev remount is harmless
useEffect(() => {
  const conn = connect()
  return () => conn.disconnect()
}, [])
```

If the double-run actually breaks something (duplicate POST, double analytics event), the effect is the wrong place for that logic — move it to an event handler, or make the operation idempotent.

---

## Effect vs Event Handler

**Symptom**: Effect that only makes sense in response to a user action.

```ts
// ❌ Effect triggered by state flag
const [submitted, setSubmitted] = useState(false)
useEffect(() => {
  if (submitted) {
    sendForm(data)
    setSubmitted(false)
  }
}, [submitted, data])

// ✅ Just call it in the handler
const handleSubmit = () => { sendForm(data) }
```

**Rule of thumb**: If the logic responds to a user action (click, submit, keypress), it belongs in an event handler, not an effect.

---

## Real-World Scenario: Search with Debounce

```ts
function useSearch(query: string) {
  const [results, setResults] = useState<SearchResult[]>([])

  useEffect(() => {
    if (!query) { setResults([]); return }

    const controller = new AbortController()

    const timeoutId = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`, {
          signal: controller.signal,
        })
        if (res.ok) setResults(searchResultsSchema.parse(await res.json()))
      } catch (err) {
        if (err instanceof DOMException && err.name === 'AbortError') return
        console.error(err)
      }
    }, 300)

    return () => {
      clearTimeout(timeoutId)
      controller.abort()
    }
  }, [query])  // query is a primitive string → stable

  return results
}
```

**Why this is correct**:
- `query` is a string (primitive) → no unstable reference
- Timeout debounces rapid typing
- AbortController cancels in-flight requests on cleanup
- Cleanup runs before each new effect invocation
- Response is schema-parsed at the trust boundary, not trusted as `SearchResult[]`

**In production**: server state like this belongs in TanStack Query — `useQuery` keyed on a debounced `query` gets you caching, dedup, and retries for free. This hand-rolled version exists to teach the effect mechanics.

---

## Safe Recommendation Template

When diagnosing an effect bug:

1. **Identify the symptom** (loop, stale data, leak, wrong trigger, dev double-run)
2. **Check dependencies** — objects/arrays/functions? → destructure, memoize, or `useEffectEvent`
3. **Check closures** — reading state directly? → updater fn, `useEffectEvent` (19.2+), or effect-synced ref
4. **Check cleanup** — every subscription/listener/timer cleaned up? (StrictMode double-run is the test)
5. **Check if it should be an effect at all** — user action? → event handler
