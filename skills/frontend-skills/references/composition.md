# React Composition Patterns

Build flexible, maintainable component APIs. Avoid the boolean-prop explosion that makes components unowned and unowned-able.

## The Core Principle

**Each new boolean prop doubles the possible states.** Three booleans = 8 combinations to test, document, and reason about. Five = 32. The fix is not better booleans — it's composition.

## 1. Avoid Boolean Prop Proliferation

### Anti-pattern

```tsx
function Composer({
  onSubmit, isThread, channelId, isDMThread, dmId, isEditing, isForwarding,
}: Props) {
  return (
    <form>
      <Header />
      <Input />
      {isDMThread ? <AlsoSendToDM id={dmId} />
        : isThread ? <AlsoSendToChannel id={channelId} />
        : null}
      {isEditing ? <EditActions />
        : isForwarding ? <ForwardActions />
        : <DefaultActions />}
      <Footer onSubmit={onSubmit} />
    </form>
  )
}

// Callers
<Composer isThread channelId="c1" />
<Composer isDMThread dmId="d1" />
<Composer isEditing />
<Composer isForwarding />
```

Six unreachable combinations are spelled out in the prop interface. The reader has to mentally compose them.

### Compound-components fix

```tsx
function ChannelComposer() {
  return (
    <Composer.Frame>
      <Composer.Header />
      <Composer.Input />
      <Composer.Footer>
        <Composer.Attachments />
        <Composer.Formatting />
        <Composer.Emojis />
        <Composer.Submit />
      </Composer.Footer>
    </Composer.Frame>
  )
}

function ThreadComposer({ channelId }: { channelId: string }) {
  return (
    <Composer.Frame>
      <Composer.Header />
      <Composer.Input />
      <AlsoSendToChannelField id={channelId} />
      <Composer.Footer>
        <Composer.Formatting />
        <Composer.Emojis />
        <Composer.Submit />
      </Composer.Footer>
    </Composer.Frame>
  )
}

function EditComposer() {
  return (
    <Composer.Frame>
      <Composer.Input />
      <Composer.Footer>
        <Composer.Formatting />
        <Composer.Emojis />
        <Composer.CancelEdit />
        <Composer.SaveEdit />
      </Composer.Footer>
    </Composer.Frame>
  )
}
```

Each variant is explicit. They share `Composer.*` internals without sharing a monolithic parent.

### When booleans ARE OK

- **HTML-style attributes:** `disabled`, `required`, `hidden`, `selected`. They map 1:1 to a DOM state.
- **Single-axis modifier on a primitive:** `<Button loading>` on a leaf button. Fine.
- **One** non-DOM boolean. Two is a smell. Three is "stop, refactor."

## 2. Compound Components

The shape:

```tsx
// 1. Context for shared state
const ModalContext = createContext<ModalContext | null>(null)
function useModal() {
  const ctx = useContext(ModalContext)
  if (!ctx) throw new Error('Modal.* must be used inside <Modal>')
  return ctx
}

// 2. Root provides the context
export function Modal({ children, open, onClose }: { children: ReactNode; open: boolean; onClose: () => void }) {
  return (
    <ModalContext.Provider value={{ open, onClose }}>
      {open ? <div className="fixed inset-0">{children}</div> : null}
    </ModalContext.Provider>
  )
}

// 3. Sub-components consume the context
Modal.Header = function Header({ children }: { children: ReactNode }) {
  return <header className="border-b p-4">{children}</header>
}
Modal.CloseButton = function CloseButton() {
  const { onClose } = useModal()
  return <button onClick={onClose} aria-label="Close">×</button>
}
Modal.Body = function Body({ children }: { children: ReactNode }) {
  return <div className="p-4">{children}</div>
}
```

Usage:

```tsx
<Modal open={open} onClose={close}>
  <Modal.Header>
    <h2>Edit profile</h2>
    <Modal.CloseButton />
  </Modal.Header>
  <Modal.Body>
    <form>…</form>
  </Modal.Body>
</Modal>
```

The Modal doesn't dictate header layout, doesn't take a `title` prop, doesn't ship 12 variants.

## 3. State: Lift Into the Provider

When siblings need the same state, don't pass callbacks around — lift state into a provider that owns it.

```tsx
// BAD — parent threads state through callbacks
function Page() {
  const [filter, setFilter] = useState('')
  return (
    <>
      <SearchBar value={filter} onChange={setFilter} />
      <ResultsList filter={filter} />
      <ResultCount filter={filter} />
    </>
  )
}

// GOOD — provider owns it; siblings subscribe
const FilterContext = createContext<{ filter: string; setFilter: (v: string) => void } | null>(null)

function FilterProvider({ children }: { children: ReactNode }) {
  const [filter, setFilter] = useState('')
  return <FilterContext.Provider value={{ filter, setFilter }}>{children}</FilterContext.Provider>
}

function useFilter() {
  const ctx = useContext(FilterContext)
  if (!ctx) throw new Error('Wrap in <FilterProvider>')
  return ctx
}

function Page() {
  return (
    <FilterProvider>
      <SearchBar />
      <ResultsList />
      <ResultCount />
    </FilterProvider>
  )
}
```

Siblings stay decoupled from each other and from `Page`'s layout.

## 4. State: Decouple Implementation from Interface

The provider is the **only** place that knows whether state lives in `useState`, Zustand, server, a ref, or URL. Consumers see one interface.

```tsx
// interface — what consumers see
type CartContext = {
  state: { items: CartItem[]; total: number }
  actions: { add: (id: string) => void; remove: (id: string) => void; clear: () => void }
  meta: { loading: boolean; error: Error | null }
}

// implementation can swap
function CartProvider({ children }: { children: ReactNode }) {
  // could be useState, useReducer, Zustand, server-backed — consumers don't care
  const [items, setItems] = useState<CartItem[]>([])
  const value: CartContext = {
    state: { items, total: items.reduce((s, i) => s + i.price, 0) },
    actions: {
      add: (id) => setItems(xs => [...xs, /* … */]),
      remove: (id) => setItems(xs => xs.filter(x => x.id !== id)),
      clear: () => setItems([]),
    },
    meta: { loading: false, error: null },
  }
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>
}
```

When the cart goes from local-only to server-backed, the components don't change.

## 5. Explicit Variants Over `mode`/`variant` Props

```tsx
// BAD — branches inside
function Card({ variant, ...props }: { variant: 'default' | 'highlighted' | 'danger' }) {
  return (
    <div className={variant === 'danger' ? 'border-red-500' : variant === 'highlighted' ? 'border-blue-500' : 'border-neutral-200'}>
      {/* lots of conditional rendering */}
    </div>
  )
}

// GOOD — distinct components, share primitives
function Card({ children, className }: CardProps) {
  return <div className={cn('rounded-xl border border-neutral-200 p-4', className)}>{children}</div>
}
function HighlightCard({ children }: { children: ReactNode }) {
  return <Card className="border-blue-500 bg-blue-50">{children}</Card>
}
function DangerCard({ children }: { children: ReactNode }) {
  return <Card className="border-red-500 bg-red-50">{children}</Card>
}
```

For controlled design-system variants (where the variant set is closed and small), `class-variance-authority` (`cva`) is the right abstraction — it gives you typed variants without conditional spaghetti.

## 6. Children Over Render Props

```tsx
// LESS PREFERRED — render prop
<List items={items} renderItem={(item) => <Row key={item.id} item={item} />} />

// PREFERRED — children
<List>
  {items.map(item => <Row key={item.id} item={item} />)}
</List>
```

Render props are still fine when the parent must inject data the child wouldn't otherwise have (`<Tooltip>{(open) => …}</Tooltip>` style). For simple iteration, children read better.

## 7. React 19 Specifics

### `use()` replaces `useContext()`

`use(Context)` works in conditionals, loops, and inside other hooks. `useContext` doesn't.

```tsx
// React 18
const theme = useContext(ThemeContext)

// React 19
import { use } from 'react'
const theme = use(ThemeContext)
```

### Context is its own Provider

In React 19, you render `<Context>` directly. The `.Provider` accessor still works but is deprecated.

```tsx
const ThemeContext = createContext<Theme | null>(null)

// React 18 — Provider accessor
<ThemeContext.Provider value={theme}>{children}</ThemeContext.Provider>

// React 19 — render the context itself
<ThemeContext value={theme}>{children}</ThemeContext>
```

### No more `forwardRef`

Refs are just props in React 19:

```tsx
// React 18
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => <input ref={ref} {...props} />)

// React 19
function Input({ ref, ...props }: Props & { ref?: Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />
}
```

### Actions and form integration

```tsx
'use client'
import { useActionState } from 'react'
import { saveProfile } from './actions'

function ProfileForm() {
  const [state, formAction, isPending] = useActionState(saveProfile, { error: null })
  return (
    <form action={formAction}>
      <input name="name" />
      {state.error && <p>{state.error}</p>}
      <button disabled={isPending}>Save</button>
    </form>
  )
}
```

`useOptimistic` gives you immediate UI updates with server-action rollback on failure.

## Red Flags

- **Adding a 3rd boolean prop.** Stop. Reach for compound or variants.
- **Passing the same callback through 3+ component layers.** Lift state into a provider.
- **A component that takes `renderHeader`, `renderBody`, `renderFooter` props.** Use compound (`X.Header`, `X.Body`, `X.Footer`).
- **`{condition ? <A /> : <B />}` repeated with the same condition in multiple files.** The condition belongs higher; the branches are sibling components.
- **`forwardRef` in React 19 code.** Ref is a prop now.
- **`useContext` inside a conditional or loop.** Use `use()`.

## Self-Audit Checklist

- [ ] No component has more than 2 non-DOM boolean props
- [ ] Compound components have a clear root that owns context
- [ ] State that siblings share lives in a provider, not the nearest common parent
- [ ] Provider interface is `{ state, actions, meta }`, not a `useState` setter
- [ ] React 19+ code uses `use()` not `useContext`, no `forwardRef`
