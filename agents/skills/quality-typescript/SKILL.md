---
name: quality-typescript
description: Use when a TypeScript codebase needs stronger domain types, branded types, discriminated unions with exhaustiveness checks, strict compiler flags, `satisfies`/`unknown`/`as const` over `enum`, removal of escape hatches like `@ts-ignore`/`as any`/non-null assertions/hand-rolled type guards, end-to-end type flow, derived types instead of duplicated interfaces, typed error handling with Result types, or real integration tests over mocks.
---

# Writing quality full-stack TypeScript

Apply these principles when writing or reviewing TypeScript code.

## Turn on the flags that make this bite

None of the discipline below holds without a strict compiler. Enable `strict`, plus `noUncheckedIndexedAccess` (array/record access yields `T | undefined`) and `exactOptionalPropertyTypes` (a missing key and an explicit `undefined` stop being the same thing). Without `noUncheckedIndexedAccess` especially, "impossible states" leaks at every index access.

These flags govern first-party code and are cheapest on greenfield. Retrofitting `exactOptionalPropertyTypes` onto an existing codebase means fighting third-party type definitions that will never comply — scope it to your own code and don't block on library types you can't fix.

## Make impossible states unrepresentable

Use the type system to make invalid states fail at compile time. Fewer reachable states = easier code to read and change.

### Branded types

Brand primitives so they can't be mixed up. Validate once at the boundary; downstream code trusts the type. Use a `unique symbol` brand so two brands can't structurally collide and the phantom key stays invisible to tooling:

```ts
declare const brand: unique symbol;
type Brand<T, B> = T & { readonly [brand]: B };

type PhoneNumber = Brand<string, "PhoneNumber">;

function parsePhone(input: string): PhoneNumber {
  if (!/^\+?\d{10,15}$/.test(input)) throw new Error(`Invalid: ${input}`);
  return input as PhoneNumber;
}

function sendSMS(to: PhoneNumber, body: string) {
  /* input is trusted */
}
```

Throwing at the boundary is fine; returning a `Result` (or the project validator's output) composes better when the caller wants to handle failure. If the project already uses a library with native branded-type support (e.g. Effect), use their primitives instead of rolling your own.

### Discriminated unions over flag bags

```ts
// Don't - invalid combos representable
type State = { loading: boolean; user?: User; error?: string };

// Do - only valid states exist
type State =
  | { status: "loading" }
  | { status: "success"; user: User }
  | { status: "error"; error: string };
```

The same smell hides in optional-everything interfaces — `{ id?: string; items?: Item[]; error?: string }` where every field is `?` because one type is trying to describe every lifecycle stage at once. Model each stage as its own union variant; a field should be optional only when it's genuinely optional in every state, not as a hedge against "sometimes it isn't there yet".

Pair every union with an exhaustiveness check so adding a variant becomes a compile error, not a silent fallthrough. Assign the narrowed value to a `never` local in the default arm and throw; no helper needed, and the throw still catches a bad discriminant that slipped past a boundary at runtime:

```ts
function render(state: State) {
  switch (state.status) {
    case "loading":
      return spinner();
    case "success":
      return profile(state.user);
    case "error":
      return banner(state.error);
    default: {
      const _exhaustive: never = state; // new variant -> type error here
      throw new Error(`Unhandled state: ${JSON.stringify(_exhaustive)}`);
    }
  }
}
```

### Constructive modeling

Build the type from parts that are all legal instead of restricting a loose type with runtime checks. TypeScript has no refinement types (no `arr.length > 0` at the type level); you don't need them.

```ts
type NonEmpty<T> = [T, ...T[]];

// Don't: T[] plus a length check every caller must repeat; seedless reduce() throws on []
function heaviest(items: Item[]): Item {
  if (items.length === 0) throw new Error("no items");
  return items.reduce((a, b) => (a.weight > b.weight ? a : b));
}

// Do: an empty value of the type can't exist, so seedless reduce() is total
function heaviest(items: NonEmpty<Item>): Item {
  return items.reduce((a, b) => (a.weight > b.weight ? a : b));
}

// Where a plain T[] arrives, narrow once; the fact then travels in the type
const isNonEmpty = <T>(arr: T[]): arr is NonEmpty<T> => arr.length > 0;
```

Same move elsewhere: even-length list as `[T, T][]`; a time range as `{ start: Date; durationMs: number }` instead of `{ start; end }` with a comment holding `start <= end`. The cross-field invariant disappears; if a raw negative number could still sneak in, brand `durationMs` as a validated nonnegative `Duration` rather than re-adding the check everywhere. Pick the representation that makes the bad state unconstructable, then expose the reading you need on top (`pairs.flat()`, a `rangeEnd()` helper).

### Simplest total type

Don't strengthen everything. Keep `T[]` while every operation on it stays total (`xs.reduce((a, b) => a + b, 0)` is fine on `[]`). Strengthen only when the loose type forces a lie at a use site. The tells are `!`, `arr[0] as T`, and a "should never happen" throw:

```ts
// Don't: partiality smuggled past the compiler
function newestSession(sessions: Session[]): Session {
  return sessions.at(0)!;
}

// Do: strengthen the input; the assertion disappears
function newestSession(sessions: NonEmpty<Session>): Session {
  return sessions[0];
}
```

Weakening the result to `Session | undefined` is the other total signature. Either way the empty case lands at the call site, the one place that knows what empty means.

## Let the types flow end-to-end

DB schema -> server -> client should share types without manual duplication. Use whatever end-to-end type tool the project already has (tRPC, oRPC, Elysia, TanStack Start). A `users.email` branded as `Email` should arrive on the client still branded.

Don't restate types you can derive. Reach for `Pick`, `Omit`, `Parameters`, `ReturnType`, `Awaited`, `typeof` etc. before writing a new interface. Derive from the schema — the source of truth — and give the derived type a name in one place. Deep `ReturnType`/`Awaited` chains re-derived at every call site couple your domain to arbitrary queries and make hovers and errors unreadable.

```ts
// Don't - duplicate shape, drifts when the row changes
type UserSummary = { id: string; email: Email };
function renderUser(u: UserSummary) {
  /* ... */
}

// Do - derive once from the schema, the source of truth
type User = typeof users.$inferSelect; // drizzle; prisma/zod have equivalents
function renderUser(u: Pick<User, "id" | "email">) {
  /* ... */
}
```

## Pass objects, not positional args

```ts
// Don't - swap two args, still compiles
sendEmail("Welcome!", "Hi there");
// Do - order-independent, self-documenting
sendEmail({ to: "alice@x.com", body: "Hi there" });
```

Positional is fine for one or two distinct, well-typed params. Switch to an object once you have three or more, or any same-typed neighbors that could be swapped silently. Skip on hot paths (per-frame render, tokenizers, parsers, tight loops) where the allocation cost matters.

## Prefer `satisfies`, `unknown`, and `as const`

`satisfies` checks a value against a type without widening it - you keep the narrow literal type and still get the constraint. This is the right tool whenever an annotation would throw away information:

```ts
// Annotation widens: routes.home is now string, keys aren't checked against a union
const routes: Record<string, string> = { home: "/", about: "/about" };

// satisfies keeps literal types AND verifies the shape
const routes = {
  home: "/",
  about: "/about",
} satisfies Record<string, `/${string}`>;
// routes.home is "/", typos in values are still caught
```

More defaults in the same spirit:

- **`unknown` over `any`** at every untyped boundary (JSON, `catch`, third-party). `unknown` forces you to narrow before use; `any` disables the checker silently.
- **Never `Function`, `{}`, or bare `object` as types.** `Function` accepts any callable and erases parameters and return type — write the signature: `(order: Order) => void`. `{}` means "anything non-nullish", not "empty object"; use a precise shape, `Record<string, never>` for truly empty, or `unknown`.
- **`as const` unions or const objects over `enum`.** Enums emit runtime code, don't behave like plain unions, and have surprising assignability. A `const` object plus a derived union covers the same ground with none of the footguns:

```ts
const Role = { admin: "admin", member: "member" } as const;
type Role = (typeof Role)[keyof typeof Role]; // "admin" | "member"
```

## Don't silence the checker

Suppressions are the checker turned off with extra steps. Treat every one as a defect to fix, not a tool to reach for:

- **`@ts-nocheck` — never.** It unchecks the whole file.
- **`@ts-ignore` — never.** It suppresses the next line forever, even after the underlying error is fixed. If suppression is truly unavoidable (usually a third-party types bug), use `@ts-expect-error` with a reason comment — it becomes an error itself once stale.
- **`as any` and `as unknown as T` double casts** launder a value past the checker with zero verification. Narrow, validate, or fix the source type instead.
- **Bare `as T`** is a runtime crash waiting. Cast only after validation has earned it (the `return data as User` at the end of a parse function).
- **Non-null assertions (`!`)** are unchecked promises about runtime state. Prefer narrowing, a thrown error with context, or fixing the type so the value can't be null there.

Hand-rolled type predicates deserve the same suspicion. A `function isFoo(x): x is Foo` is an `as` cast wearing a function costume — the compiler trusts the body blindly, so a wrong or stale guard is a silent unsafe cast. `isRecord`/`isObject`/`isDefined` helpers sprinkled through internal code mean the boundary type was never fixed; parse and validate once at the boundary (with the project's schema validator) and let downstream code trust the type. Reserve `is` predicates for the rare case narrowing genuinely can't be expressed inline via discriminants, `in`, `typeof`, or `instanceof` — and keep the body trivially verifiable.

When narrowing, prefer in this order: discriminant `switch`/`if` > `in` operator > `typeof`/`instanceof` > user-defined type guard > `as`.

When refactoring an `as` out of existing code, find out why TypeScript can't infer:

- Missing discriminant: add one, switch to a discriminated union.
- Overly wide source type (e.g. `Record<string, unknown>`): narrow it.
- Untyped boundary: add a parse function or schema.
- Genuinely inexpressible: use a branded type or `satisfies`.

Enforce mechanically where the project lints: `@typescript-eslint/ban-ts-comment` (with `ts-expect-error: allow-with-description`), `no-explicit-any`, and `no-non-null-assertion`.

## Handle errors with types, not vibes

`catch` variables are `unknown` under strict — keep them that way and narrow before use. Throw `Error` subclasses (never strings), name domain errors, and chain causes so the original failure survives translation:

```ts
try {
  await chargeCustomer(order);
} catch (err) {
  if (err instanceof GatewayTimeoutError) {
    throw new RetryablePaymentError(order.id, { cause: err });
  }
  throw err;
}
```

For failures the caller is expected to handle, prefer a discriminated Result union over throwing — the failure shows up in the signature and exhaustiveness checking applies:

```ts
type ParseResult<T> = { ok: true; value: T } | { ok: false; error: string };
```

Handle every promise. An unawaited, un-`.catch`ed promise is a silently swallowed failure; enable `@typescript-eslint/no-floating-promises` where the project lints.

## Standard Schema for shared validation

For libraries or shared utilities that should not force callers onto one validator, accept `StandardSchemaV1<unknown, T>` instead of a concrete Zod/Valibot/ArkType schema type. Application code can keep using the project's chosen validator directly; library-like code should depend on the common interface.

```ts
import type { StandardSchemaV1 } from "@standard-schema/spec";

type ParserOptions<T> = {
  schema: StandardSchemaV1<unknown, T>;
};

async function parseBody<T>(request: Request, options: ParserOptions<T>): Promise<T> {
  const input: unknown = await request.json();
  const result = await options.schema["~standard"].validate(input);

  if (result.issues) {
    throw new Error("Invalid request body");
  }

  return result.value;
}
```

Use this at package boundaries where the caller should choose the validator. Do not wrap every local schema in Standard Schema just for abstraction's sake.

## Tests as real as possible

Don't mock things you can run. Spin up real services:

- LocalStack for AWS
- Miniflare for Cloudflare Workers
- Real Postgres/SQLite (e.g. `bun:sqlite`), not a mock DB

Mock only third-party services that have no test environment.

Real services are slower, so don't make every test pay for them: real services at the integration boundary, fast isolated tests for pure logic underneath.

## The common TypeScript red flags

Prioritize fixing non-strict tsconfig, `any` at boundaries, `as` casts instead of narrowing, `as unknown as` double casts, `@ts-ignore`/`@ts-nocheck`/undocumented `@ts-expect-error`, non-null assertions and "should never happen" throws that a `NonEmpty`-style input type would remove, hand-rolled `isRecord`-style type guards over unparsed boundaries, `Function`/`{}` as types, optional-everything interfaces, flag-bag state types, `enum`, hand-duplicated types that drift from the source of truth, same-typed positional args, thrown strings, `catch` blocks that assume `Error`, floating promises, missing exhaustiveness checks, and mock-heavy tests for things you could run for real.
