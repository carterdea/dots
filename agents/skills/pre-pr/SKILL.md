---
name: pre-pr
description: Run complete validation before creating a PR - security, tests, breaking changes, and generate PR description
user-invocable: true
disable-model-invocation: true
---

# Pre-PR Validation Pipeline

Complete validation pipeline to run before creating a pull request.

## Pipeline Overview

PHASE 1: SECURITY & COMPLIANCE (Blocking)
  1. Security Scanner      -> Secrets, OWASP
  2. Compliance Checker    -> Project rules
  3. Architecture Validator-> Layer boundaries

PHASE 2: QUALITY (Blocking)
  4. Test Coverage Gate    -> Tests exist
  5. Breaking Change Check -> API compatibility
  6. Performance Analyzer  -> N+1, blocking I/O

PHASE 3: POLISH (Non-blocking)
  7. Type Modernization    -> Modern Python types
  8. Code Simplification   -> Refactoring suggestions

PHASE 4: OUTPUT
  9. Run Tests             -> pytest / vitest
  10. Run Linters          -> ruff, basedpyright, biome
  11. Generate PR Desc     -> Ready-to-paste description

## Execution

### Step 1: Gather Context
git branch --show-current
git log main..HEAD --oneline
git diff --name-only main...HEAD

### Step 2: Determine Scope
Based on changed files, run appropriate checks:
- `.py` files -> Python pipeline
- `.ts` files -> TypeScript backend checks
- `.tsx` files -> Frontend checks

### Phase 1: Security & Compliance (BLOCKING)

#### 1.1 Security Scan
- Hardcoded secrets
- SQL/Command injection
- SSRF risks

STOP if CRITICAL or HIGH issues found.

#### 1.2 Compliance Check
- Python: python-compliance-checker
- TypeScript: Check for `any`, `let`, proper imports

#### 1.3 Architecture Validation
- Layer boundaries respected
- No circular imports
- Proper dependency injection

### Phase 2: Quality (BLOCKING)

#### 2.1 Test Coverage
- Check modified files have tests
- Verify coverage meets minimum

#### 2.2 Breaking Changes
- API changes
- Schema changes
- Configuration changes

WARN if breaking changes detected.

#### 2.3 Performance Analysis
- N+1 queries
- Blocking I/O
- Inefficient patterns

### Phase 3: Polish (NON-BLOCKING)

#### 3.1 Type Modernization
- Suggest modern type syntax
- Offer to fix automatically

#### 3.2 Code Simplification
- Complexity reduction opportunities
- Refactoring suggestions

### Phase 4: Final Verification

#### 4.1 Run Tests
# Python
cd chat-services && uv run pytest -x -v

# TypeScript Backend
cd backend && bun run test

# Frontend
cd frontend && bun run test

#### 4.2 Run Linters
# Python
cd chat-services && uv run ruff check . && uv run basedpyright

# TypeScript
bun run lint && bun run typecheck

#### 4.3 Generate PR Description

## Options

- `--quick` - Fast mode, critical checks only
- `--no-tests` - Skip test execution
- `--python-only` - Only check Python code
- `--typescript-only` - Only check TypeScript code
