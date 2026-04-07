---
name: subagent-orchestrator
description: Orchestrate sub-agents to accomplish complex long-horizon tasks without losing coherency
user-invocable: true
disable-model-invocation: true
---

# Sub-Agent Orchestrator

Maintain coherency in long-horizon, context-heavy tasks by delegating all non-trivial operations to sub-agents.

## Core Principle

Your main thread is a **coordinator**, not a worker. Keep it lean -- delegate everything, synthesize results, decide next steps. The moment you start doing heavy lifting inline, you lose coherency.

## Delegation Rules

### Research and Understanding
Delegate to sub-agents with `subagent_type`:
- **Explore** -- codebase analysis, pattern discovery, file/symbol location
- **Plan** -- architecture decisions, implementation strategy

### Shell and Infrastructure
Delegate to **general-purpose** sub-agents when:
- Running CLI tools that produce verbose output (`aws`, `gh`, `docker`, `kubectl`, logs)
- Investigating runtime state, debugging, or inspecting infrastructure
- Any bash command where output may exceed ~50 lines

### Code Changes
Delegate to **general-purpose** sub-agents (optionally with `isolation: "worktree"`) when:
- Implementing a discrete, well-scoped change
- Running tests after a change
- Fixing lint/type errors

## Parallelism

- Launch independent sub-agents in parallel (single message, multiple Agent tool calls).
- Do NOT split tasks with significant overlap across separate sub-agents -- they'll duplicate work and may conflict.
- When results from one sub-agent inform the next, run them sequentially.

## Coordinator Responsibilities

You (the main thread) should:
1. **Decompose** the task into discrete sub-problems.
2. **Dispatch** each sub-problem to the right sub-agent type.
3. **Synthesize** results as they return -- reconcile conflicts, fill gaps.
4. **Decide** next steps based on synthesized understanding.
5. **Report** progress to the user at natural milestones.

You should NOT:
- Read large files inline (delegate to Explore).
- Run long bash commands inline (delegate to general-purpose).
- Hold more context than needed -- let sub-agents hold the details.

## Briefing Sub-Agents

Each sub-agent starts with zero context. Brief them like a colleague who just walked in:
- What you're trying to accomplish and why.
- What you've already learned or ruled out.
- Enough surrounding context for judgment calls.
- Whether you expect research only or code changes.

Terse command-style prompts produce shallow work. Never delegate understanding -- include file paths, line numbers, and specifics you already know.

## Task Flow

### If the user has already given you a task
Proceed immediately using this orchestration approach. Decompose, dispatch, synthesize.

### If no task has been given
Ask the user what they'd like to work on. Do not assume or begin working on anything automatically.

## Anti-Patterns

- **Doing research yourself** when a sub-agent could do it -- you'll bloat your context.
- **Delegating vaguely** ("figure out the codebase") -- be specific about what to find.
- **Serial execution** of independent tasks -- parallelize.
- **Re-reading sub-agent results in full** -- extract what you need, discard the rest.
- **Losing track of the plan** -- after every sub-agent round, restate where you are.
