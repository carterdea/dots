---
name: quality-ruby
description: Use when writing, reviewing, or refactoring Ruby or Rails code that needs smaller methods, guard clauses, clearer service objects, thinner Rails models/controllers/jobs, safer ActiveRecord queries, explicit error handling, better RSpec tests, idiomatic Enumerable usage, transaction boundaries, timezone correctness, or removal of junior Ruby smells like silent rescue, callback-heavy workflows, mystery hashes, broad services, and N+1 queries.
---

# Writing quality Ruby

Apply these principles when writing or reviewing Ruby and Rails code. Prefer idiomatic, explicit Ruby over clever metaprogramming, and keep Rails framework concerns from swallowing the domain.

## Keep methods and objects honest

Huge methods, deep conditionals, and too many instance variables usually mean the code has lost its boundary. Extract small private methods only while the class still has one responsibility. If private methods pile up, extract a collaborator.

Use guard clauses to make failure paths obvious.

```ruby
def can_ship?(order)
  return false unless order
  return false unless order.customer
  return false unless order.customer.address

  order.items.any?
end
```

Avoid vague objects named `UserService`, `OrderManager`, or `Processor`. Name the action or domain operation: `CancelOrder`, `SyncCustomerToKlaviyo`, `PriceOrder`.

Boolean positional arguments make call sites unreadable. Prefer keyword args or separate methods.

```ruby
activate(user, send_welcome_email: true, sync_to_klaviyo: false)
```

## Keep Rails layers thin

Controllers should authorize, load/normalize inputs, call an operation, and render. They should not contain workflows.

Models should own persistence rules and small domain behavior, not every business process. Fat models, callback chains, and broad concerns hide execution paths. Move workflows into explicit services, jobs, query objects, policies, form objects, presenters, or components as appropriate.

Jobs should orchestrate background execution and call a domain operation. Do not bury core business logic directly in `perform`.

Views should render. Move complex conditionals into helpers, presenters, decorators, components, or named domain predicates. Avoid turning helpers into another dumping ground.

## Prefer explicit domain shapes over mystery hashes

Hashes are fine at Rails boundaries, but do not pass mystery hashes through the whole app. Permit, copy, and normalize params into plain hashes, value objects, structs, DTOs, or models. Normalize symbol/string keys at the boundary.

Use constants, symbols, enums, or domain objects instead of stringly typed business logic.

```ruby
class OrderPricing
  VIP_DISCOUNT = 0.8

  def initialize(order)
    @order = order
  end

  def total
    return subtotal * VIP_DISCOUNT if order.customer.vip?

    subtotal
  end

  private

  attr_reader :order

  def subtotal
    order.subtotal
  end
end
```

## Handle errors deliberately

Never use silent `rescue nil`. Avoid broad `rescue StandardError` unless you are at a boundary and will log, translate, or re-raise intentionally. Rescue the exact exception expected.

When absence is expected, do not use exceptions to detect it — use the API that returns `nil`:

```ruby
# Don't - exception as control flow
def customer_email(customer_id)
  Customer.find(customer_id).email
rescue ActiveRecord::RecordNotFound
  nil
end

# Do - absence is a normal outcome
def customer_email(customer_id)
  Customer.find_by(id: customer_id)&.email
end
```

If a missing object is meaningful to the caller, return a domain result or raise a domain error instead of hiding it as `nil`.

Use bang methods consistently: `!` should mean the method raises, mutates dangerously, or otherwise has a sharper contract.

Avoid exceptions for normal control flow. Prefer predicates, early returns, result objects, or explicit domain outcomes.

## Be precise with nil and presence

Excessive `&.`, `try`, `present?`, and `blank?` can hide unclear data expectations. Use them where the distinction truly does not matter. When it does matter, validate earlier or check exactly: `nil?`, `empty?`, `false`, or a domain predicate.

Avoid `||=` memoization when `false` or `nil` is a valid cached value. Use `defined?`, an explicit sentinel, or a small memoization helper.

## Make ActiveRecord behavior intentional

Watch for N+1 queries. Use `includes`, `preload`, `eager_load`, joins, batch loading, or query objects where appropriate.

Wrap related multi-write operations in a transaction. Do not make external API calls inside a transaction; commit database work first, then enqueue a job or call the external system.

Use `update_all`, `save(validate: false)`, and callback-skipping APIs deliberately. They bypass normal Rails behavior and should make their intent obvious.

Keep migrations version-independent. Avoid calling app models or business logic that may change later. Define reversible migrations with `up/down` or `reversible` when rollback matters.

Authorize at the controller/action/query boundary. Do not rely on hidden UI checks.

## Write idiomatic Ruby

Use `each` for side effects, `map`/`filter_map`/`flat_map` for transformations, and named intermediate variables when Enumerable chains get clever.

Avoid Java-style Ruby and unnecessary boilerplate. Use blocks, keyword args, predicate methods ending in `?`, and bang methods ending in `!` only when the contract warrants it.

Avoid monkey patching core classes. Prefer wrappers, modules with narrow scope, or refinements when truly needed.

Avoid clever metaprogramming and dynamic method names unless the DSL earns the search/debug cost.

## Treat time, config, and secrets carefully

Use `Time.zone` in Rails apps and freeze time in specs that depend on it. Avoid raw-second date math when Rails duration helpers or date APIs express the rule.

Centralize ENV access and config loading. Do not scatter credentials, hardcoded IDs, or feature flags across the app.

Redact tokens, secrets, and PII from logs. Ensure Rails parameter filtering covers sensitive fields.

Avoid mutable global state and class variables. They pollute tests and can be unsafe under Puma or Sidekiq.

## Test behavior, not implementation

RSpec should prove observable behavior. Avoid specs that mock every collaborator and only assert internal calls. Use integration/request/system specs for core flows, and focused unit specs for isolated domain logic.

Keep setup readable. Avoid `let` soup, giant factories, and unrelated fixture data. Prefer explicit setup, smaller contexts, minimal factories, traits, and `build_stubbed` where persistence is unnecessary.

Freeze time in tests that care about timezones or durations. Test authorization, failure paths, transactions, and query behavior when they are part of the risk.

## The common Ruby red flags

Prioritize fixing huge Rails models/controllers, nested `if` pyramids, mystery hashes, silent rescue, callback-driven business workflows, clever metaprogramming, specs that mock everything, N+1 queries, business logic in views/helpers, non-idiomatic Enumerable usage, external calls inside transactions, scattered ENV access, and inconsistent return contracts.
