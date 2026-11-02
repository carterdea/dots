# Source and installation

Source: [emilkowalski/skills](https://github.com/emilkowalski/skills/tree/f1090bec277140d02ed202440185ad9d02ac1490/skills/write-swift).
Revision: `f1090bec277140d02ed202440185ad9d02ac1490`, resolved from upstream `main` on 2026-11-02.
License: MIT, Copyright (c) 2026 Emil Kowalski. The upstream root notice is copied to [LICENSE](LICENSE).

Installed with Codex's reviewed `install-skill-from-github.py` helper, using the pinned revision and an explicit dots `agents/skills` destination.
The only change to upstream content is removal of a trailing blank line at EOF in `SKILL.md`, so `git diff --check` passes. The source hashes below describe the original upstream files. `LICENSE` and this provenance record were added.
The selected skill contains Markdown only. No bundled code or dependencies were executed or installed.
References to other upstream skills are optional guidance; only the six requested skills were installed.

## Reviewed upstream SHA-256 values

| File | SHA-256 |
| --- | --- |
| `SKILL.md` | `16a4b6adb74e338e55e704ce5753ad54d825438b8a63930eeaede9f3c04c9447` |
| Upstream root `LICENSE` | `4ff5bdb7887ec1435c9cab0e8d1a7caee704d894d65c2a008ccc68b1cc2f260b` |

## Global use

Use `/write-swift` in Claude Code or `$write-swift` in Codex. Available on the next turn; start a new session if an existing catalog has not refreshed.
Both `~/.claude/skills/write-swift` and `~/.agents/skills/write-swift` point to this directory in the isolated dots worktree at `/Users/carterdeangelis/Sites/dots-emil-skills`.
Keep that worktree while these links are active. After integrating the commit into the primary dots checkout, repoint these six links to its `agents/skills` directories before removing the worktree.
