---
name: babysit-pr
description: Run PR comment handling and CI fixes together.
user-invocable: true
disable-model-invocation: true
---

Babysit the requested PR using both skills:

- Invoke [gh-address-pr-comments](../gh-address-pr-comments/SKILL.md) to address review feedback and watch for new comments.
- Invoke [gh-fix-ci](../gh-fix-ci/SKILL.md) to diagnose and fix failing checks.

Keep both on the same PR. Any push requires checking both again; finish when both skills' completion conditions hold for the current head, or report their blocker. This request does not authorize merging.
