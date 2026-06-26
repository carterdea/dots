-- Migration: YYYYMMDDHHMMSS_descriptive_name.sql
-- Description: [What this migration does]
-- Dialect: PostgreSQL
-- Author: [Your Name]
-- Date: YYYY-MM-DD
--
-- Notes:
-- - PostgreSQL supports transactional DDL for these statements.
-- - For MySQL/MariaDB, remove the transaction wrapper and account for implicit
--   commits around DDL.
-- - Replace placeholder table/column names before use.

-- migrate:up
BEGIN;

CREATE TABLE IF NOT EXISTS table_name (
  id BIGSERIAL PRIMARY KEY,
  reference_id BIGINT,
  column_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_table_column ON table_name (column_name);
CREATE INDEX idx_table_reference_id ON table_name (reference_id);

ALTER TABLE table_name
  ADD CONSTRAINT fk_table_reference
  FOREIGN KEY (reference_id) REFERENCES other_table(id)
  ON DELETE CASCADE;

-- Data migration, if needed:
-- UPDATE table_name SET new_column = old_column;

COMMIT;

-- migrate:down
BEGIN;

ALTER TABLE table_name DROP CONSTRAINT IF EXISTS fk_table_reference;
DROP INDEX IF EXISTS idx_table_reference_id;
DROP INDEX IF EXISTS idx_table_column;
DROP TABLE IF EXISTS table_name;

COMMIT;

-- Validation examples:
-- SELECT to_regclass('public.table_name');
-- SELECT indexname FROM pg_indexes WHERE tablename = 'table_name';
