---
name: code-review-prompt
description: Generate a comprehensive code review prompt for the current branch that can be copied into another Claude session
allowed-tools: Bash
user-invocable: true
---

# Code Review Prompt Generator

Generate a prompt for reviewing the current branch's code changes.

## Instructions

1. Run `git branch --show-current` to get the current branch name
2. Run `git log main..HEAD --oneline` to get commits on this branch
3. Run `git diff --name-status main` to get changed files
4. Count the commits and categorize files by directory and file extension
5. Detect the technology stack from file extensions:
   - `.py` → Python (FastAPI, Django, Flask, etc.)
   - `.rb` → Ruby (Rails, etc.)
   - `.ts`, `.tsx` → TypeScript (React, Node, etc.)
   - `.js`, `.jsx` → JavaScript
   - `.go` → Go
   - `.rs` → Rust
   - `.java` → Java
   - `.php` → PHP
   - `.swift` → Swift
   - etc.

Then output the following prompt in a markdown code block so the user can copy it:

````markdown
Review the code changes on this branch for quality, correctness, and adherence to best practices.

## Branch Info
- Branch: {branch_name}
- Base: main
- Commits: {commit_count}

## Changed Files
{file_list_grouped_by_directory_and_type}

## Recent Commits
{commit_messages}

## Technology Stack Detected
{list_detected_technologies_from_file_extensions}

## Review Checklist

### 1. Architecture & Design
- [ ] Follows established patterns in the codebase
- [ ] No unnecessary complexity or over-engineering
- [ ] Proper separation of concerns
- [ ] No anti-patterns introduced
- [ ] Dependencies are properly managed

### 2. Technology-Specific Best Practices
For each detected technology, use Context7 to verify against current documentation:

{dynamically_generate_sections_based_on_detected_stack}

Examples:
- **Python**: Type hints, async/await patterns, error handling, dependency injection
- **Ruby/Rails**: ActiveRecord patterns, service objects, controller actions, migrations
- **TypeScript/React**: Component design, hooks usage, state management, type safety
- **Node.js**: Async patterns, error handling, middleware design
- **Go**: Error handling, goroutines, interfaces, package structure
- **Rust**: Ownership, borrowing, error handling, trait usage
- **Java/Spring**: Dependency injection, service layers, exception handling
- **PHP/Laravel**: Eloquent usage, middleware, validation, authorization

### 3. Code Quality
- [ ] Functions are focused and reasonably sized
- [ ] Files are organized and not too large
- [ ] No duplicated logic (DRY violations)
- [ ] Proper error handling (not silently swallowing errors)
- [ ] No security vulnerabilities (injection, XSS, CSRF, etc.)
- [ ] Tests cover critical paths and edge cases
- [ ] No hardcoded secrets or credentials

### 4. Consistency
- [ ] Follows project naming conventions
- [ ] Import/require statements organized properly
- [ ] Code style matches existing codebase
- [ ] Comments explain "why" not "what"
- [ ] No commented-out code left behind

### 5. Performance
- [ ] No obvious performance issues (N+1 queries, unnecessary loops)
- [ ] Efficient data structures used
- [ ] Proper caching where appropriate
- [ ] Database queries optimized

### 6. Testing
- [ ] Tests are clear and focused
- [ ] Edge cases covered
- [ ] No flaky tests
- [ ] Test names describe what they test

## Output Format
For each issue found:
1. File and line reference
2. Issue description
3. Severity (critical/warning/suggestion)
4. Recommended fix with code example

Summarize with: issues by severity, overall assessment, and whether this is ready to merge.
````

Replace the placeholders with actual values from the git commands and detected technologies.
