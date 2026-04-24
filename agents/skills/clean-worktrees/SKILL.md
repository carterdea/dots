---
name: clean-worktrees
description: Audit and clean agent-created Git worktrees (Codex, Claude Code, OpenCode, Pi, or plain `git worktree add`) and leftover worktree directories safely. Use when disk usage appears inflated by `~/.codex/worktrees`, per-repo `.claude/worktrees`, `.worktrees`, other agent worktree roots, Git worktree metadata, detached worktrees, stale branch worktrees, or when the user asks to map worktrees to pull requests before deletion.
---

# Clean Worktrees

Use this skill when any agent's worktree root is large, when `git worktree list` has accumulated cruft, or when the user asks which worktrees are safe to remove. Works for every harness that creates worktrees.

## Known Worktree Roots

Different agents use different conventions. Scan all that apply:

- **Codex**: `~/.codex/worktrees` (global, one dir per worktree)
- **Claude Code**: per-repo, typically `<repo>/.claude/worktrees/*` or `<repo>/.worktrees/*`
- **OpenCode**: per-repo `<repo>/.opencode/worktrees/*` or shared `~/.config/opencode/worktrees`, depending on setup
- **Pi**: per-repo `<repo>/.pi/worktrees/*` or `~/.pi/agent/worktrees`
- **Manual**: any path created by `git worktree add <path> <branch>`

The default script mode scans **every registered worktree** for the target repo except the primary checkout, so all of the above are covered automatically. Use `--root` (repeatable) to narrow scope.

## Workflow

1. Measure disk first:
   ```bash
   df -h / /System/Volumes/Data
   du -sh ~/.codex/worktrees 2>/dev/null
   find . -maxdepth 3 -type d \( -name worktrees -o -name ".worktrees" \) -exec du -sh {} \; 2>/dev/null
   ```

2. Audit before cleanup. Locate `clean_worktrees.py` under whichever agent skill dir is installed (any of these symlink to the same file):
   - `~/.claude/skills/clean-worktrees/scripts/clean_worktrees.py`
   - `~/.agents/skills/clean-worktrees/scripts/clean_worktrees.py` (Codex)
   - `~/.config/opencode/skills/clean-worktrees/scripts/clean_worktrees.py`
   - `~/.pi/agent/skills/clean-worktrees/scripts/clean_worktrees.py`

   Audit-only (all worktrees for a repo):
   ```bash
   python3 ~/.claude/skills/clean-worktrees/scripts/clean_worktrees.py \
     --repo ~/path/to/repo \
     --audit-dir ~/.worktree-cleanup-audit \
     --min-age-hours 24
   ```

   Narrow to a specific root (repeatable):
   ```bash
   python3 ~/.claude/skills/clean-worktrees/scripts/clean_worktrees.py \
     --repo ~/path/to/repo \
     --root ~/.codex/worktrees \
     --root ~/path/to/repo/.claude/worktrees \
     --root ~/path/to/repo/.worktrees \
     --audit-dir ~/.worktree-cleanup-audit
   ```

3. Interpret risk:
   - **Clean detached worktrees**: safest to remove.
   - **Dirty detached worktrees**: back up status, diff, and untracked files before removal.
   - **Named branch worktrees without an open PR**: usually safe after checking dirty status.
   - **Named branch worktrees with an open PR**: keep unless the user explicitly asks to remove them.
   - **Main checkout or non-worktree path**: never remove as part of automatic cleanup.

4. Apply cleanup only after the audit result is clear:
   ```bash
   python3 ~/.claude/skills/clean-worktrees/scripts/clean_worktrees.py \
     --repo ~/path/to/repo \
     --audit-dir ~/.worktree-cleanup-audit \
     --apply \
     --include-dirty \
     --min-age-hours 24
   ```

5. Prune repository metadata after removals (script already runs this on `--apply`, but safe to repeat):
   ```bash
   git -C ~/path/to/repo worktree prune
   ```

6. Verify:
   ```bash
   git -C ~/path/to/repo worktree list --porcelain
   du -sh ~/.codex/worktrees 2>/dev/null
   df -h / /System/Volumes/Data
   ```

## Pull Request Mapping

For named branch worktrees, map branches to PRs before deletion:

```bash
gh -C <repo> pr list --head <branch> --json number,title,url,state,headRefName,baseRefName
```

Detached worktrees do not map cleanly to PRs by branch. Treat them as not PR-backed unless the worktree has a named branch or a remote branch can be inferred from local metadata.

## Safety Rules

- Default to audit-only.
- Do not delete by raw `rm` or `rm -rf`.
- Save audit artifacts under a dedicated audit directory, such as `~/.worktree-cleanup-audit`.
- For dirty worktrees, save:
  - `git status --porcelain`
  - `git diff --binary`
  - an archive of untracked files
- Skip worktrees modified within the configured age window, default `24` hours, to avoid deleting active sessions.
- Skip PR-backed branches unless the user explicitly says to delete them.
- Use Git's own `worktree remove --force` for registered worktrees.
- Move unregistered leftover directories (only under explicit `--root`) to `~/.Trash/worktrees/<timestamp>/` instead of deleting them directly. Override via `--trash-dir`.
