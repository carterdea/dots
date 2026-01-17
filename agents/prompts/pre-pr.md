---
description: Run complete validation before creating a PR - security, tests, breaking changes, and generate PR description
---

# Pre-PR Validation Pipeline

Complete validation pipeline to run before creating a pull request.

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRE-PR PIPELINE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PHASE 1: SECURITY & COMPLIANCE (Blocking)                  │
│  ├── 1. Security Scanner      → Secrets, OWASP              │
│  ├── 2. Compliance Checker    → Project rules               │
│  └── 3. Architecture Validator→ Layer boundaries            │
│                                                             │
│  PHASE 2: QUALITY (Blocking)                                │
│  ├── 4. Test Coverage Gate    → Tests exist                 │
│  ├── 5. Breaking Change Check → API compatibility           │
│  └── 6. Performance Analyzer  → N+1, blocking I/O           │
│                                                             │
│  PHASE 3: POLISH (Non-blocking)                             │
│  ├── 7. Type Modernization    → Modern Python types         │
│  └── 8. Code Simplification   → Refactoring suggestions     │
│                                                             │
│  PHASE 4: OUTPUT                                            │
│  ├── 9. Run Tests             → pytest / vitest             │
│  ├── 10. Run Linters          → ruff, basedpyright, biome   │
│  └── 11. Generate PR Desc     → Ready-to-paste description  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Execution

### Step 1: Gather Context
```bash
# Get branch info
git branch --show-current
git log main..HEAD --oneline

# Get changed files
git diff --name-only main...HEAD
```

### Step 2: Determine Scope
Based on changed files, run appropriate checks:
- `.py` files in `chat-services/` → Python pipeline
- `.ts` files in `backend/` → TypeScript backend checks
- `.tsx` files in `frontend/` → Frontend checks

### Phase 1: Security & Compliance (BLOCKING)

#### 1.1 Security Scan
Run security-scanner agent:
- Hardcoded secrets
- SQL/Command injection
- SSRF risks

**STOP if CRITICAL or HIGH issues found.**

#### 1.2 Compliance Check
Run appropriate compliance checker:
- Python: python-compliance-checker
- TypeScript: Check for `any`, `let`, proper imports

#### 1.3 Architecture Validation
Run architecture-validator:
- Layer boundaries respected
- No circular imports
- Proper dependency injection

### Phase 2: Quality (BLOCKING)

#### 2.1 Test Coverage
Run test-coverage-gate:
- Check modified files have tests
- Verify coverage meets minimum

#### 2.2 Breaking Changes
Run breaking-change-detector:
- API changes
- Schema changes
- Configuration changes

**WARN if breaking changes detected.**

#### 2.3 Performance Analysis
Run performance-analyzer:
- N+1 queries
- Blocking I/O
- Inefficient patterns

### Phase 3: Polish (NON-BLOCKING)

#### 3.1 Type Modernization
Run python-type-fixer (for Python files):
- Suggest modern type syntax
- Offer to fix automatically

#### 3.2 Code Simplification
Run python-code-simplifier:
- Complexity reduction opportunities
- Refactoring suggestions

### Phase 4: Final Verification

#### 4.1 Run Tests
```bash
# Python
cd chat-services && uv run pytest -x -v

# TypeScript Backend
cd backend && bun run test

# Frontend
cd frontend && bun run test
```

#### 4.2 Run Linters
```bash
# Python
cd chat-services && uv run ruff check . && uv run basedpyright

# TypeScript
bun run lint && bun run typecheck
```

#### 4.3 Generate PR Description
Run pr-description-gen to create:
- Summary of changes
- Test plan
- Breaking changes section
- Checklist

## Output Format

```
## Pre-PR Validation Report

### Branch: feature/my-feature
### Commits: 5 (since main)
### Files Changed: 12

---

## Phase 1: Security & Compliance

### Security Scan
Status: PASS
- Critical: 0
- High: 0
- Medium: 1 (logging issue - non-blocking)

### Compliance Check
Status: PASS
- Violations: 0

### Architecture
Status: PASS
- Layer violations: 0
- Circular imports: 0

---

## Phase 2: Quality

### Test Coverage
Status: PASS
- Modified files with tests: 8/8
- Coverage: 82%

### Breaking Changes
Status: WARNING
- API changes detected:
  - POST /api/chat now requires `sessionId`
- Recommendation: Document in PR description

### Performance
Status: PASS
- Issues: 0

---

## Phase 3: Polish

### Types
Status: OK
- No legacy types found

### Simplification
Status: INFO
- 2 opportunities identified
- Lines reducible: ~30

---

## Phase 4: Verification

### Tests
Status: PASS
- Python: 45 passed, 0 failed
- TypeScript: 23 passed, 0 failed

### Linters
Status: PASS
- Ruff: OK
- Basedpyright: OK
- Biome: OK

---

## Overall: READY FOR PR

### PR Description (copy below):

[Generated PR description here]

---

### Remaining Actions
1. [ ] Document breaking change in PR description
2. [ ] Consider refactoring suggestions (optional)
```

## Quick Mode

For fast validation during development:
```
/pre-pr --quick
```

Runs only:
1. Security scan (critical only)
2. Linters
3. Tests

## Options

- `--quick` - Fast mode, critical checks only
- `--no-tests` - Skip test execution
- `--python-only` - Only check Python code
- `--typescript-only` - Only check TypeScript code
