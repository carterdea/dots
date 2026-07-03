---
name: quality-python
description: Use when writing, reviewing, or refactoring Python code that needs cleaner structure, precise types, better error handling, safer IO, smaller functions, clearer domain models, Ruff/uv tooling, async correctness, realistic tests, or removal of junior Python smells like broad exceptions, mutable defaults, dict blobs, global config, silent fallbacks, and `Any` everywhere.
---

# Writing quality Python

Apply these principles when writing or reviewing Python code. Prefer the project's existing style, but push code toward small, explicit, typed, testable modules.

## Keep shape and ownership obvious

Python gets sloppy when scripts, utilities, and business logic blur together. Keep CLI and script entrypoints thin; put reusable behavior in named modules and functions. Split large modules by responsibility instead of creating a vague `utils.py` dumping ground.

Prefer module-level functions over fake service classes full of `@staticmethod`s. Use classes when you need state, polymorphism, or a domain concept with behavior. Use composition before inheritance.

```python
# Don't - fake object, unclear responsibility
class UserService:
    @staticmethod
    def process(data):
        ...

# Do - focused operation with a specific contract
def activate_user(user: User, *, send_welcome_email: bool) -> User:
    ...
```

Keep functions small enough to scan. When a function mixes validation, IO, branching, mutation, and formatting, split it around the real phases of the workflow. Use guard clauses to flatten nested control flow.

## Name the domain, not the mechanics

Avoid names like `data`, `obj`, `thing`, `handle`, `process`, and `do_stuff` unless the domain is genuinely generic. Name the thing being transformed and the outcome.

Do not shadow built-ins such as `list`, `dict`, `id`, `type`, or `file`. Use `items`, `mapping`, `user_id`, `kind`, or a domain-specific name.

Use Python naming conventions consistently: `snake_case` for variables and functions, `PascalCase` for classes, named constants for magic strings and numbers.

## Model data explicitly

Dict blobs are one of the fastest ways to make Python code fragile. At boundaries, parse and validate raw input. Inside the application, prefer `dataclass`, `TypedDict`, Pydantic models, domain objects, enums, or small value objects.

```python
# Don't - fragile keys everywhere
user = {"id": 123, "email": "a@example.com", "is_admin": False}

# Do - a readable contract
from dataclasses import dataclass


@dataclass(frozen=True)
class User:
    id: int
    email: str
    is_admin: bool
```

Use `Decimal` or integer cents for money. Avoid floats and money-as-strings for values that will be calculated.

## Make types honest

Add type hints to public APIs, domain code, and functions whose contracts matter. No type hint is better than a lying one, but precise types are better than both. Hints only pay off when a checker enforces them; run the project's type checker (basedpyright and ty are good defaults).

Avoid `Any` unless the value is truly unknowable at the boundary. Use `object`, `Protocol`, `TypedDict`, generics, unions, or validators to narrow the shape. Treat `Any` like `# type: ignore`: rare, local, and justified.

Return one predictable shape. Avoid functions that sometimes return `None`, sometimes `False`, sometimes a string, and sometimes an object. Use `Optional[T]`, domain exceptions, result objects, or a clear default intentionally.

## Keep error handling intentional

Never use bare `except:`. Avoid `except Exception: pass`; it hides production failures and makes tests lie. Catch the narrow exception you expect, attach useful context, and either handle it completely or re-raise with chaining.

```python
try:
    charge_customer(order)
except PaymentGatewayTimeout as exc:
    logger.warning("Payment gateway timeout", extra={"order_id": order.id})
    raise RetryablePaymentError(order.id) from exc
```

Do not use exceptions for ordinary branching. Do not return status strings that callers must parse. Define domain-specific exceptions or result types when callers need to respond cleanly.

Silent fallback defaults are suspicious. Fail loudly unless the fallback is an explicit product or operational decision.

## Design functions around one job

Avoid mutable default arguments. Use `None` and initialize inside the function.

```python
def add_user(user: User, users: list[User] | None = None) -> list[User]:
    if users is None:
        users = []

    return [*users, user]
```

Boolean flags often mean one function does multiple jobs. Split separate workflows, or use keyword-only arguments when the flag is genuinely configuration.

Keep IO separate from pure computation where practical. Pure logic is cheap to test; IO should be thin and explicit.

Avoid hidden mutation. Return new values unless mutation is the point of the function and the name makes that clear.

## Write idiomatic control flow

Use direct iteration and `enumerate()` instead of `range(len(items))`. Use `if items:` instead of `len(items) > 0`. Use `is None` for `None`, `==` for equality, and avoid clever comprehensions when a named loop is clearer.

Do not mutate collections while iterating over them. Build a new collection or iterate over a copy.

Use `pathlib.Path` for paths, context managers for resources, `json.dumps()` for JSON, and `subprocess.run([...], check=True)` for commands. Avoid `shell=True` with untrusted input.

## Centralize config and boundaries

Do not read environment variables throughout the codebase. Load and validate config once at the boundary, then pass typed config inward.

Validate API, CLI, file, and queue inputs before they reach business logic. Normalize raw DB/API objects into domain objects or DTOs when that improves clarity.

Never hardcode secrets, credentials, or environment-specific IDs.

## Treat IO, network, and async code as failure-prone

Always set network timeouts. Retry only operations that are safe or explicitly idempotent. Reuse clients where safe instead of creating them per request.

Stream or chunk large files instead of loading them fully into memory.

In async code, do not call blocking libraries or `time.sleep()`. Use async-compatible libraries and `await asyncio.sleep()`. Keep sync/async boundaries clear and push async orchestration to the app boundary.

## Handle time explicitly

Use timezone-aware datetimes for anything stored, compared, or crossing a boundary: `datetime.now(tz=UTC)` or `zoneinfo`, never naive `datetime.now()`. Do not mix naive and aware values. Freeze time in tests that depend on it instead of sleeping or comparing against the real clock.

## Log for diagnosis without leaking data

Use `logging`, not committed print debugging. Include operation names and IDs that let someone trace a failure. Redact tokens, secrets, and PII.

If a failure matters, log it, raise it, or return an explicit failure. Do not make it disappear.

## Test behavior, edges, and failures

Test pure logic directly. At integration boundaries, use realistic services when feasible: test DBs, local emulators, fixtures, and factories. Mock external services, not internal implementation details.

Avoid massive fixtures, `time.sleep()` in tests, and mocks that prove only that code called itself. Prefer factories/builders, fake clocks, polling helpers, and dependency injection.

Prefer `uv` for Python commands and Ruff for linting/formatting when the project has no stronger existing standard.

## The common Python red flags

Prioritize fixing broad exception handling, big functions that mix IO and business logic, dict blobs, global config/state, vague names, unclear error models, missing timeouts, naive datetimes, fake service classes, `Any` sprawl, over-mocked tests, silent fallbacks, mutable default args, code running on import, clever comprehensions, and inconsistent returns.
