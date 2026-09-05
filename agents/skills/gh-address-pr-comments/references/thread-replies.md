# Reply and resolve

When asked to address comments or babysit a PR, reply autonomously on known bot threads and Carter's own threads. For other humans' threads, or threads another human has joined, fix valid code issues but draft the reply and leave resolution pending until Carter approves the wording and closure. Do not let a bot-owned opening comment override later human participation.

Use the actual executing model identifier from the session; never invent a version. If only the model family is available, use that and say the exact version is unavailable.

```md
[MODEL-SLUG] RESPONDING ON BEHALF OF CARTER
-----

[Concise verdict, code evidence, and pushed fix SHA or superseding SHA.]
```

For outdated findings, explain how the current code supersedes the cited issue before resolving. For false positives, cite the relevant code and why the claim does not apply. Do not automatically resolve an outstanding explanation request or disagreement.

Immediately before writing, re-read that thread's resolution state and all submitted comments, paginating as needed. If it is already resolved, stop. If new feedback arrived, triage it first. Respect `viewerCanReply` and `viewerCanResolve`; report missing permission. Use the thread node id from the helper, not a comment id.

Write the exact reply to a temporary UTF-8 file, then post it with a file-backed argument:

```bash
gh api graphql -f query='mutation($thread: ID!, $body: String!) { addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $thread, body: $body}) { comment { id url } } }' -f thread="$THREAD_ID" -F body=@"$REPLY_FILE"
```

Check for GraphQL `errors` as well as a returned comment id. If a request times out, re-read the thread before retrying to avoid duplicate replies. A successful reply followed by a failed resolution should retry only resolution.

Re-read for intervening feedback after replying. Once the response and any pushed fix account for every submitted concern, resolve:

```bash
gh api graphql -f query='mutation($thread: ID!) { resolveReviewThread(input: {threadId: $thread}) { thread { id isResolved } } }' -f thread="$THREAD_ID"
```

Require no GraphQL errors and `isResolved: true`. Report a race or permission failure instead of claiming closure. GitHub has no equivalent resolution state for top-level PR comments; reply when authorized and record them as handled locally.

Use existing screenshots or videos when they help prove a finding. Obtain Carter's approval before uploading attachments; link an already approved artifact when available.
