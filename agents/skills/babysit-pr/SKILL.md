---
name: babysit-pr
description: Run PR comment handling and CI fixes together.
user-invocable: true
disable-model-invocation: true
---

Babysit the requested PR. Own the polling loop; invoke each specialist sequentially in **single-pass mode with shipping authorized**. Neither specialist waits for future remote results. Stop immediately on either specialist's blocker before invoking the next pass. Preserve their thread tracking and CI retry history across passes. This request does not authorize merging.

## Each cycle

1. Invoke [gh-address-pr-comments](../gh-address-pr-comments/SKILL.md) for available feedback. Use its resolved PR and repository for both skills throughout the run.
2. Invoke [gh-fix-ci](../gh-fix-ci/SKILL.md) on the resulting head for one CI pass.
3. End the run if the PR is merged, closed, or superseded.
4. Recheck both after any head change. Discard approval and check results for older SHAs. A push, fix, new or edited feedback, failed check, or CI rerun resets the quiet period and clean-poll count.
5. Finish only when both passes describe the same current head, CI is green, GitHub reports `mergeable: MERGEABLE`, no review is pending, no actionable feedback remains, and review is approved or the quiet period below has elapsed. Verify the remote head and mergeability again before reporting completion. Keep polling while mergeability is unknown; route conflicts through the review specialist and stop with a blocker if they cannot be safely resolved.
6. Otherwise, if a pass changed the head, start the next cycle immediately. If not, wait five minutes once for both skills, using interruptible waits or intervals of at most 60 seconds. Stay quiet about unchanged polls unless updates were requested.

The quiet period requires four clean polls separated by five minutes, spanning at least 20 minutes since the last reset. A clean poll requires a mergeable PR, green CI, no pending review, and no unresolved actionable feedback. The first observation starts the clock; it does not count as elapsed time. Unknown mergeability or pending or unknown CI prevents completion and breaks consecutive clean polls.

Report the PR, final head, fixes, thread resolutions, validation, and whether the run ended on approval, sustained quiet, or a blocker. Keep diagnosis and repair instructions in the specialist skills.
