---
name: new-cmd
description: Create a new skill from conversation history or user description
user-invocable: true
disable-model-invocation: true
---

# New Command

Create a skill from conversation history or user description.

## Steps

1. **Detect context**
   - If history exists: auto-capture workflow into skill
   - If no history: parse user's description
   - Use thread context clues to infer name, description, and usage

2. Determine host (Codex, Claude, Cursor) from current runtime
   - Say: "Since I am {host}, I will install it in {host}"

3. Check existing skills for style (host-specific)
ls ~/.codex/skills/
ls ~/.claude/skills/
ls ~/.cursor/skills/
ls agents/skills/

4. Propose the skill name, description, usage, location, and key steps first
   - Proceed unless user rejects or corrects

5. Create skill structure:
{skill-name}/
  SKILL.md

6. Write SKILL.md with frontmatter:
---
name: skill-name
description: one-line
user-invocable: true
disable-model-invocation: true
---

# Skill Name

One-line description.

## Steps
1. Step with `bash command`
2. Step with decisions

## Usage
/{name} [args]

7. Report created file and usage

## Flags

`--interview`: Ask detailed questions about purpose, triggers, inputs, outputs

## Rules

- Default to capturing conversation if history exists
- Default host to current runtime and install there
- Ask at most one question, only if ambiguity blocks execution
- Infer everything else from context
- Create skills in `agents/skills/{name}/SKILL.md`
