---
description: Run the complete Python QA pipeline on chat-services code
---

# Python QA Pipeline

Execute the complete QA workflow on chat-services Python code.

## Pipeline Overview

```
┌─────────────────────────────────────────────────────┐
│              PYTHON QA PIPELINE                     │
├─────────────────────────────────────────────────────┤
│  1. Security Scan       → Secrets, injections       │
│  2. Compliance Check    → NEVER rules               │
│  3. Type Modernization  → PEP 585/604 types         │
│  4. Architecture Check  → Layer boundaries          │
│  5. Performance Check   → N+1, blocking I/O         │
│  6. Code Simplification → Refactoring proposals     │
│  7. Verification        → ruff + basedpyright       │
└─────────────────────────────────────────────────────┘
```

## Pipeline Steps

### Step 1: Find Target Files
```bash
# Get recently modified Python files
git diff --name-only HEAD~5 | grep '\.py$' | grep chat-services || echo "Using all files"
```

If user specified a file or directory, use that instead.

### Step 2: Security Scan (CRITICAL)
Check for security vulnerabilities:
- Hardcoded secrets (API keys, passwords)
- SQL injection risks
- Command injection
- Sensitive data in logs
- SSRF vulnerabilities

**STOP if CRITICAL issues found.**

### Step 3: Compliance Check
Check for NEVER rule violations:
- Walrus operator (`:=`)
- Tuples (should be `list`)
- Legacy typing (`Optional[`, `List[`, `Dict[`)
- Bare except / pass blocks
- Print statements (should use logging)
- Relative imports

### Step 4: Type Modernization
Check for legacy type annotations:
- `Optional[X]` → `X | None`
- `List[X]` → `list[X]`
- `Dict[K, V]` → `dict[K, V]`

If found, offer to fix them.

### Step 5: Architecture Validation
Check for architecture violations:
- Layer boundary violations (api → graphs directly)
- Circular imports
- God modules (>300 lines)
- Improper dependency injection

### Step 6: Performance Analysis
Check for performance anti-patterns:
- N+1 queries in loops
- Sequential await (should use gather)
- Blocking I/O in async functions
- Inefficient string operations
- Missing batching for embeddings/queries

### Step 7: Code Simplification
Analyze for simplification opportunities:
- Functions over 25 lines
- Nesting depth > 2
- Duplicate error handling patterns
- Silent except blocks

Propose changes but wait for confirmation.

### Step 8: Verification
Run linting and type checking:
```bash
cd chat-services && uv run ruff check --fix .
cd chat-services && uv run basedpyright
```

## Output Format

```
## Python QA Pipeline Report

### Files Analyzed
- chat_service/api/chat.py
- chat_service/graphs/nodes/embed.py

### Step 1: Security Scan
- Status: PASS / FAIL
- Critical: 0
- High: 0
- Details: [if any issues]

### Step 2: Compliance Check
- Violations: X
- Files affected: Y
- Most common: [type]

### Step 3: Type Modernization
- Legacy types found: 0 / X
- Status: PASS / NEEDS FIX

### Step 4: Architecture
- Layer violations: 0
- Circular imports: 0
- God modules: 0

### Step 5: Performance
- Critical issues: 0
- High issues: X
- Details: [N+1 query at line X]

### Step 6: Simplification
- Opportunities: X
- Lines reducible: ~Y

### Step 7: Verification
- Ruff: PASS / X issues
- Basedpyright: PASS / X errors

### Overall Status: PASS / FAIL

### Recommended Actions
1. [Priority action]
2. [Secondary action]
```

## Quick Mode

For fast iteration, run only critical checks:
```
/python-qa --quick
```

This runs only:
1. Security scan
2. Compliance check
3. Verification
