---
name: quality-react
description: Use when writing, reviewing, or refactoring React code that needs smaller components, clearer state ownership, fewer unnecessary effects, typed props, semantic HTML, accessible form controls, explicit loading/error/empty states, safer async effects, Next.js server/client boundaries, cleaner hooks, better tests, or removal of junior React smells like derived state in `useEffect`, prop drilling, index keys, `any` props, clickable divs, Tailwind class chaos, and premature abstraction.
---

# Writing quality React

Apply these principles when writing or reviewing React code. Prefer small, typed, accessible components with explicit state ownership and boring data flow.

## Split components by responsibility

A component should not fetch data, own permissions, manage multiple modals, validate forms, run mutations, and render a dense page all at once. Split by responsibility: route/page orchestration, data hooks, presentational pieces, forms, tables, and focused actions.

```tsx
function DashboardPage() {
  return (
    <>
      <DashboardHeader />
      <DashboardStats />
      <RecentOrdersTable />
    </>
  )
}
```

Do not overcorrect into generic component systems before the product shape is stable. Start concrete; extract only when duplication is real and the shared concept has a clear name.

## Own state at the right level

Keep state as close as practical to where it is used. Do not lift local UI state into a global store, context, or page component unless multiple distant consumers truly need it.

Store the minimal source of truth. Derive everything else during render.

```tsx
const [selectedUserId, setSelectedUserId] = useState(user.id)
const selectedUser = users.find(user => user.id === selectedUserId)
```

Avoid boolean explosions like `isLoading`, `isSaving`, `hasError`, and `isSuccess` when one status union expresses the real state.

```tsx
type Status = "idle" | "loading" | "success" | "error"
const [status, setStatus] = useState<Status>("idle")
```

Flatten deep state, split state by concern, or use a reducer. Avoid long nested spread updates that make one field change hard to reason about.

## Use effects only for effects

Do not use `useEffect` for derived values. Compute them during render.

```tsx
const fullName = `${firstName} ${lastName}`
```

Effects are for synchronizing with external systems: network subscriptions, browser APIs, timers, imperative widgets, analytics, and storage. Include real dependencies. Treat disabled hook lint rules as rare exceptions that need a code comment explaining why restructuring is not practical.

Always clean up listeners, timers, and subscriptions. For async effects, guard against stale updates with abort controllers, cancellation flags, or a query library.

```tsx
useEffect(() => {
  const controller = new AbortController()

  fetchUser(userId, { signal: controller.signal }).then(setUser)

  return () => {
    controller.abort()
  }
}, [userId])
```

Avoid cargo-cult `useMemo`, `useCallback`, and `memo`. Use them for expensive work, referential stability needed by a child/API, or measured hot paths.

## Make data flow explicit

Avoid prop drilling through components that do not use the prop. Use composition, route-level data, focused context, or colocated fetching.

Keep contexts narrow. One app-wide context holding user, cart, theme, permissions, checkout, modal, and random UI state becomes a hidden global store.

Use a data-fetching layer for repeated server state patterns. Components should not all reinvent loading/error/data state around raw `fetch` calls. Centralize API access instead of calling random endpoints directly from components.

Map raw API responses into UI/domain shapes before rendering. Do not make components reach through backend response internals.

Use URL state for shareable filters, search, sorting, and pagination. Keep purely local draft state local.

## Type component contracts

Avoid `any` props and weak event types. Define props and use React event types.

```tsx
type ProductCardProps = {
  product: Product
}

function ProductCard({ product }: ProductCardProps) {
  return <div>{product.title}</div>
}

function handleChange(event: React.ChangeEvent<HTMLInputElement>) {
  setEmail(event.target.value)
}
```

Use domain-specific component and prop names. `CustomerCard` with `customer` is clearer than `DataCard` with `data`.

Prefer named exports unless the framework requires default exports. Avoid huge barrel files that hide import boundaries and create circular dependencies.

## Keep render logic readable

Name complex conditions before JSX. Use early returns instead of nested ternaries. Move domain rules out of markup into named functions.

```tsx
const canRefundOrder =
  user?.isAdmin && order.status !== "cancelled" && !order.refunded

return <>{canRefundOrder && <RefundButton order={order} />}</>
```

Render intentional loading, error, empty, and success states. Do not assume data always exists. Wrap risky subtrees in error boundaries so a render crash degrades to a contained fallback instead of taking down the page; pair them with suspense boundaries where the framework uses them.

Avoid optional chaining everywhere as a substitute for data modeling. Guard or normalize earlier when a nested shape is required.

Use stable IDs for keys. Never use random keys. Use index keys only for static lists that cannot reorder, insert, or delete.

Do not set state or run side effects during render.

## Build accessible, semantic UI

Use real buttons, links, labels, inputs, forms, and headings. A clickable `div` is not a button.

Set button `type` intentionally, especially inside forms. Do not rely on placeholders as labels. Ensure keyboard and screen reader behavior follows native semantics before adding custom handlers.

Prefer uncontrolled inputs or form actions for simple submit-then-read forms; use controlled inputs when the UI must react per keystroke (live validation, filtering, dependent fields). Never switch an input between the two.

Keep Tailwind classes manageable. Extract UI primitives, variants, or `cn`/`clsx` helpers when class strings or conditional classes become hard to scan. Do not create component APIs so generic that every caller becomes a configuration puzzle.

Avoid comments that excuse fragile UI code. Fix the design, or leave a short comment explaining the external constraint and removal condition.

## Respect SSR and server/client boundaries

In Next.js and other SSR frameworks, keep server-rendered parts server-side and isolate interactivity. Do not mark large trees with `"use client"` just to support one button.

Do not read `window`, `document`, `localStorage`, random values, or `Date.now()` during SSR render. Render deterministic output first, then update client-side if needed.

Treat client-side permission checks as UX only. Enforce authorization server-side. Never expose private API keys or secrets to frontend bundles.

## Handle performance without guessing

Do not render thousands of rows directly. Paginate, filter server-side, or virtualize. Move hot state lower in the tree so typing into one input does not rerender a whole dashboard.

Avoid dependency bloat for trivial helpers. Use native browser/JavaScript APIs when they are clear.

Do not ignore React warnings: key warnings, hydration mismatches, controlled/uncontrolled inputs, and hook dependency warnings usually point to real bugs.

## Test what users do and see

Avoid snapshot-only tests. Use React Testing Library or the project's equivalent to test behavior, accessible roles, visible states, and user interactions.

Mock external boundaries, not implementation details. Test loading, error, empty, success, form validation, and permission states where they matter.

## The common React red flags

Prioritize fixing `useEffect` as a catch-all, huge components, duplicate state, boolean state explosions, prop drilling, giant context objects, vague component names, too many props, conditional JSX soup, nested ternaries, index/random keys, direct state mutation, bad effect dependencies, casual hook lint suppression, missing loading/error/empty states, missing error boundaries, optional chaining everywhere, `any` props, side effects during render, cargo-cult memoization, inaccessible clickable elements, uncleaned effects, race-prone async effects, global store abuse, raw API coupling, too much `"use client"`, and over-abstracted components/hooks.
