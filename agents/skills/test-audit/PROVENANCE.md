# Source and portability

Source: https://github.com/openclaw/openclaw/tree/71becfa19f32a86eb3e62bccf713f5be7107884f/.agents/skills/test-audit

Revision: `71becfa19f32a86eb3e62bccf713f5be7107884f` (resolved from main for this installation).
License: MIT, Copyright (c) 2026 OpenClaw Foundation. Full notice is in [LICENSE](LICENSE).
Installed using Codex's reviewed skill-installer helper with an explicit dots destination.
The upstream skill directory contains Markdown only; no bundled code or dependencies were executed.

## Adaptations

- Kept the authoring gate, junk patterns, retention bar, evidence checklist, and campaign workflow.
- Made audit discovery read-only by default, with edits governed by task authority.
- Replaced out-of-directory OpenClaw links with portable local boundary and proof guides, adapted from the two upstream guides below.
- Replaced OpenClaw-only validation scripts/dead-code commands with the target repository's supported equivalents.
- Deferred integration/rebase policy to the target repository. OpenClaw campaign examples remain illustrative.
- Did not install a separate OpenClaw testing skill, remote runner, or any dependencies.

## Reviewed upstream SHA-256 values

These are original source hashes, before the portability changes above.

| Upstream path | SHA-256 |
| --- | --- |
| `.agents/skills/test-audit/SKILL.md` | `1390c61901a1b9ec46778901ebd24f96b201989977d7b8dea2f05b7e593ab025` |
| `.agents/skills/test-audit/CAMPAIGN.md` | `c844b1df2b23153b55e1ac06c128953e956d51ecd0b6b2df3f8a33009f245ef0` |
| `.agents/skills/test-audit/references/audit.md` | `71fbcc8d3f0b423a650edc25a99f634ef7f20211c25751c54892e24a5bac3c0c` |
| `docs/help/testing/writing-tests.md` | `858a86c93c9d7e9099127e1f2d9d4b9caba2a8ddebf5260338a484e101ec8076` |
| `.agents/skills/openclaw-testing/SKILL.md` | `47b4dad7b11b9d587171d2df8e1cd27affdb3f1c13a8861e2dbf787d846e3075` |
| `LICENSE` | `9efd316ecf1c4c60f6fd5d26433142fff2b6794d7d328e9bc6179b29bf9c82a4` |

## Global use

Both `~/.claude/skills/test-audit` and `~/.agents/skills/test-audit` point to this directory,
following dots' existing Claude Code and Codex install conventions. Use `/test-audit` in
Claude Code or `$test-audit` in Codex. Open a new session/turn if an existing session's
skill catalog has not refreshed. Future edits belong here in dots.
