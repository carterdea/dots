# Database Schema Designer

Design or review database schemas from domain requirements and access patterns.

## Use When

- Designing SQL tables or MongoDB/document collections.
- Choosing SQL vs NoSQL.
- Normalizing an existing schema.
- Planning indexes from query patterns.
- Writing safe migrations.
- Auditing schema integrity, performance, or deployment risk.

## Structure

- `SKILL.md` — compact workflow, dialect policy, output shapes, completion criteria.
- `references/sql-design.md` — relational modeling, normalization, constraints, indexes, migrations, performance review.
- `references/nosql-design.md` — document modeling, embed/reference decisions, NoSQL indexes.
- `references/schema-design-checklist.md` — full design/review checklist.
- `assets/templates/migration-template.sql` — reversible PostgreSQL-style migration skeleton.

## Defaults

- PostgreSQL-compatible SQL unless the request names another dialect.
- SQL by default for transactional domains with relationships and integrity requirements.
- NoSQL only when document access patterns are known or explicitly requested.
- Every index should map to a named query pattern.
- Every migration should include rollout safety and rollback notes.
