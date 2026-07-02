---
name: database-schema-designer
description: Design or review database schemas. Use when modeling data, creating tables/collections, choosing SQL vs NoSQL, normalizing schemas, planning indexes, writing migrations, or auditing database integrity and performance.
license: MIT
---

# Database Schema Designer

Design database schemas from domain requirements and access patterns. The main job is not to emit tables quickly; it is to produce a schema that preserves data integrity, fits the workload, and can evolve safely.

## References

Load only the reference that matches the branch you are in:

- SQL schema design, normalization, data types, constraints, relationships, indexes, migrations, and performance: [`references/sql-design.md`](references/sql-design.md)
- MongoDB / document modeling, embed-vs-reference decisions, and NoSQL indexes: [`references/nosql-design.md`](references/nosql-design.md)
- Full review and deployment checklist: [`references/schema-design-checklist.md`](references/schema-design-checklist.md)
- Reversible SQL migration skeleton: [`assets/templates/migration-template.sql`](assets/templates/migration-template.sql)

## Dialect Policy

- Ask for the target database when syntax matters.
- Default examples to PostgreSQL-compatible SQL unless the request names another dialect.
- Translate identity columns, timestamp defaults, indexes, JSON types, generated columns, and migration syntax to the chosen dialect before presenting final DDL.
- Do not emit MySQL-only syntax (`AUTO_INCREMENT`, inline `INDEX`, `ON UPDATE CURRENT_TIMESTAMP`, `ALTER TABLE ... MODIFY`) for PostgreSQL or SQLite requests.
- If the request names MongoDB or document storage, switch to the NoSQL branch and model around access patterns.

## Workflow

### 1. Gather The Shape

Extract or ask for:

- Entities or collections.
- Relationships and cardinality.
- Read/write access patterns.
- Scale hints, tenancy, and retention requirements.
- Database engine and dialect.
- Existing schema or migration constraints, when this is a review or evolution task.

Completion criterion: every table/collection you propose maps to a domain concept or named access pattern, and every unknown that affects syntax or integrity is either resolved or listed as an assumption.

### 2. Choose The Storage Model

Use SQL by default for transactional domains with relationships, constraints, joins, reporting correctness, or evolving business rules.

Use NoSQL/document modeling only when access patterns are known and documents are usually read/written together, or when the user explicitly asks for it.

Completion criterion: the output states why SQL or NoSQL fits the workload, and names the tradeoff that would make the other choice better.

### 3. Design The Schema

For SQL, load [`references/sql-design.md`](references/sql-design.md). Design from the domain outward:

- Normalize to 3NF first unless a specific read path justifies denormalization.
- Define primary keys, foreign keys, `ON DELETE` behavior, `NOT NULL`, `UNIQUE`, and `CHECK` constraints.
- Choose dialect-appropriate data types.
- Add timestamps only where lifecycle tracking is useful.

For NoSQL, load [`references/nosql-design.md`](references/nosql-design.md). Design around access patterns:

- Choose embedded documents when data is read together and bounded.
- Use references when child sets are large, independently updated, or shared.
- Keep document size and update frequency explicit.

Completion criterion: every relationship has an ownership/cardinality decision, every required field has an integrity rule, and every intentional duplicate/denormalized value names the query it serves.

### 4. Plan Indexes From Queries

Indexes follow access patterns, not vibes. List the query patterns first, then add indexes for:

- Foreign keys and joins.
- High-frequency `WHERE`, `ORDER BY`, and uniqueness checks.
- Composite queries with column order matched to the query.
- Partial, text, or geospatial indexes only when the query shape calls for them.

Completion criterion: every non-primary index has a named query/use case, and the output calls out write-cost or over-indexing risks.

### 5. Plan Migration Safety

For new schemas, provide DDL and initial indexes.

For schema changes, make migrations reversible and deployment-aware:

- Add nullable columns before enforcing `NOT NULL`.
- Backfill separately from schema changes for large tables.
- Dual-write/read-compatibly for renames.
- Avoid long locks; use dialect-safe concurrent index patterns where needed.

Completion criterion: migration output includes an `UP` path, a `DOWN` path or explicit irreversible-risk note, and the rollout order needed to keep existing app versions working.

### 6. Review Before Final

Before responding, load [`references/schema-design-checklist.md`](references/schema-design-checklist.md) for any substantial design or review task.

Completion criterion: final output includes the relevant checklist results or a concise "review notes" section covering primary keys, relationships, constraints, indexes, migrations, and unresolved risks.

## Output Shape

Use the smallest useful structure for the request:

- **New schema:** assumptions, schema DDL or document shapes, indexes, migration notes, review notes.
- **Schema review:** findings ordered by severity, specific table/field/index references, fixes, and migration risk.
- **Index request:** access patterns, proposed indexes, query examples, tradeoffs.
- **Migration request:** rollout plan, `UP`, `DOWN`, backfill/dual-write notes, lock risk.
- **SQL vs NoSQL decision:** recommendation, access-pattern reasoning, rejected alternative, risk.

## Core Rules

- Model the domain, not the UI.
- Prefer database-enforced integrity over app-only conventions.
- Use `DECIMAL`/exact numeric types for money; never use floating point for currency.
- Index foreign keys unless the dialect already does and you have verified that behavior.
- Treat `SELECT *`, missing foreign keys, unbounded documents, and non-reversible migrations as review findings.
- Do not invent production scale, access patterns, or business rules. State assumptions when the prompt omits them.
