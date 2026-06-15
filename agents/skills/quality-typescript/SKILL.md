---
name: quality-typescript
description: Use when a TypeScript codebase needs stronger domain types, discriminated unions, end-to-end type flow, derived types instead of duplicated interfaces, real integration tests over mocks, or OpenTelemetry instrumentation.
---

# Writing quality full-stack TypeScript

Apply these principles when writing or reviewing TypeScript code.

## Make impossible states unrepresentable

Use the type system to make invalid states fail at compile time. Fewer reachable states = easier code to read and change.

### Branded types

Brand primitives so they can't be mixed up. Validate once at the boundary; downstream code trusts the type.

```ts
type PhoneNumber = string & { __brand: "PhoneNumber" };

function parsePhone(input: string): PhoneNumber {
  if (!/^\+?\d{10,15}$/.test(input)) throw new Error(`Invalid: ${input}`);
  return input as PhoneNumber;
}

function sendSMS(to: PhoneNumber, body: string) {
  /* input is trusted */
}
```

If the project already uses a library with native branded-type support (e.g. Effect), use their primitives instead of rolling your own.

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

Skip on hot perf-critical paths; use elsewhere by default.

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

## OpenTelemetry, not print logging

When adding observability, instrument with OTel spans. The setup cost pays back the first time a user sends a request ID and you can answer instead of guess.
