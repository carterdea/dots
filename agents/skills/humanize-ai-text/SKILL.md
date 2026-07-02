---
name: humanize-ai-text
description: Humanize AI-shaped writing. Use for "make this less AI/ChatGPT", AI writing or slop audits, citation/source checks in AI-drafted text, detector concerns, leaked citation tokens, placeholders, broken markup, or wrong target-format cleanup.
allowed-tools:
  - Read
  - Write
  - StrReplace
  - Bash
  - Glob
  - WebFetch
  - WebSearch
---

# Humanize AI Text

Use this skill to give AI-shaped prose human eyes: diagnose what feels generic, unsupported, reader-blind, or mechanically generated, then make the smallest useful rewrite. The goal is better writing and source integrity, not detector theater or claims about who wrote the text.

## Workflow

Open `patterns.md`, then review prose quality before citation mechanics unless the user specifically asks for citation verification:

1. Audience-model failures: prose that ignores what the reader knows, needs, doubts, or will do next; generic empathy; no real prioritization.
2. Fluff and LLM tells: inflated significance, vague stakes, template transitions, rhetorical balance, abstract filler, repeated cadence.
3. Claim quality: vague attribution, unsupported superlatives, stale timing, softened quantifiers, causal overreach.
4. Mechanical residue: leaked tool tokens, placeholders, broken markup, invalid references, wrong target-format syntax.
5. Citation support when relevant: real source, correct metadata, quote/page/number/date/name support, source-chaining mistakes.
6. Rewrite plan: smallest concrete fix, reader-specific framing, concrete verbs/nouns, target-format markup, and any verification still needed.

## Output

Lead with findings when the user asks for an audit, review, detector-risk check, citation check, or diagnosis. For each finding, include:

- `Issue`
- `Evidence` (exact snippet or line location)
- `Class` (`P0`, `P1`, `P2`)
- `Why it matters`
- `Possible non-AI explanation`
- `Smallest fix`
- `Confidence` (`High`, `Medium`, `Low`, or `Needs source access`)
- `File/line` when available

Use classes this way:

- `P0`: fabricated or wrong source, materially unsupported claim, quote/number/name error, broken markup that changes meaning or publication viability.
- `P1`: recurring audience-model failure, generic claim scaffold, citation metadata drift, vague attribution, unsupported quantitative/date/causal claim.
- `P2`: isolated fluff, local style cleanup, minor formatting polish.

Return the top 5-8 findings. Merge repeated symptoms under one root cause.

If the user asks to humanize, rewrite, polish, or clean up text, provide a compact replacement after any necessary findings. Preserve the user's meaning, voice, target format, and factual uncertainty. Do not add fake examples, unsupported claims, citations, numbers, case studies, or personal detail.

## Optional Scripts

The scripts are helpers for a first-pass scan, not judges. Use them when the user provides a local file or asks for broad cleanup:

```bash
uv run scripts/detect.py text.txt
uv run scripts/compare.py text.txt -o clean.txt
uv run scripts/transform.py text.txt -o clean.txt
```

They can flag leaked citation tokens, boilerplate, filler, copula avoidance, punctuation drift, and repeated AI-shaped phrases. Manual review still decides what matters.

## Guardrails

- Do not promise to bypass AI detectors or make text "undetectable".
- Do not infer AI authorship from detector scores, a single style cue, perfect grammar, formal tone, multilingual English, or translation artifacts.
- Treat suspicious markers as text-quality defects first. Name provenance risk only when objective residue or source failures justify it.
- Verify citation existence before judging claim support. If sources are unavailable, label the check as unverified and recommend the narrowest follow-up.
- Treat "lack of theory of mind" as an editorial diagnosis: the writing fails to model the reader, situation, objections, or next action. Do not use it as a claim about the writer.
- Do not moralize, shame the writer, or perform detector-score theater.
- Only patch files when the user asks for edits.

## Resource

- `patterns.md`: compact artifact taxonomy, verification checks, and rewrite guidance.
