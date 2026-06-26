---
name: quality-typescript
description: Use when a TypeScript codebase needs stronger domain types, branded types, discriminated unions with exhaustiveness checks, strict compiler flags, `satisfies`/`unknown`/`as const` over `enum`, end-to-end type flow, derived types instead of duplicated interfaces, real integration tests over mocks, or OpenTelemetry instrumentation.
---

# Writing quality full-stack TypeScript

Apply these principles when writing or reviewing TypeScript code.

## Turn on the flags that make this bite

None of the discipline below holds without a strict compiler. Enable `strict`, plus `noUncheckedIndexedAccess` (array/record access yields `T | undefined`) and `exactOptionalPropertyTypes` (a missing key and an explicit `undefined` stop being the same thing). Without `noUncheckedIndexedAccess` especially, "impossible states" leaks at every index access.

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

Pair every union with an exhaustiveness check so adding a variant becomes a compile error, not a silent fallthrough:

```ts
function assertNever(x: never): never {
  throw new Error(`Unhandled: ${JSON.stringify(x)}`);
}

function render(state: State) {
  switch (state.status) {
    case "loading":
      return spinner();
    case "success":
      return profile(state.user);
    case "error":
      return banner(state.error);
    default:
      return assertNever(state); // new variant -> type error here
  }
}
```

## Let the types flow end-to-end

DB schema -> server -> client should share types without manual duplication. Use whatever end-to-end type tool the project already has (tRPC, oRPC, Elysia, TanStack Start). A `users.email` branded as `Email` should arrive on the client still branded.

Don't restate types you can derive. Reach for `Pick`, `Omit`, `Parameters`, `ReturnType`, `Awaited`, `typeof` etc. before writing a new interface. For function arguments, infer from the source instead of typing them by hand:

```ts
// Don't - duplicate shape, drifts when the row changes
type UserSummary = { id: string; email: Email };
function renderUser(u: UserSummary) {
  /* ... */
}

// Do - derive from the source of truth
type User = NonNullable<Awaited<ReturnType<typeof db.query.users.findFirst>>>;
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

Positional is fine for one or two distinct, well-typed params. Switch to an object once you have three or more, or any same-typed neighbors that could be swapped silently.

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

Two more defaults in the same spirit:

- **`unknown` over `any`** at every untyped boundary (JSON, `catch`, third-party). `unknown` forces you to narrow before use; `any` disables the checker silently.
- **`as const` unions or const objects over `enum`.** Enums emit runtime code, don't behave like plain unions, and have surprising assignability. A `const` object plus a derived union covers the same ground with none of the footguns:

```ts
const Role = { admin: "admin", member: "member" } as const;
type Role = (typeof Role)[keyof typeof Role]; // "admin" | "member"
```

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

## Reach for tracing when you cross service boundaries

Traces, metrics, and logs are complementary, not substitutes. When you need to follow a request across services, instrument with OpenTelemetry spans rather than scattering `console.log` - the setup cost pays back the first time a user sends a request ID and you can answer instead of guess. Structured logging stays legitimate, and full OTel is overkill for a CLI or a single small service.
