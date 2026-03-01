---
name: smart-brevity
description: >
  Rewrite text using Smart Brevity principles — shorter, sharper, audience-first communication.
  Use this skill whenever the user wants to: rewrite or edit text to be more concise, apply Smart Brevity
  formatting, improve emails/newsletters/presentations/speeches/social posts/meeting agendas,
  audit a codebase or website for copy improvements, make writing punchier or clearer,
  reduce word count while preserving meaning, or mentions "Smart Brevity" in any context.
  Also trigger when the user pastes a block of text and asks to "tighten," "shorten," "clean up,"
  "make it punchy," "cut the fluff," or similar brevity-related requests. Even if the user doesn't
  say "Smart Brevity" explicitly, use this skill for any request to improve the clarity, brevity,
  or impact of written communication.
user-invocable: true
---

# Smart Brevity

Rewrite and audit text using the Smart Brevity system — a framework for saying more with less,
developed by the founders of Axios and Politico.

## Overview

Smart Brevity is a system for thinking more sharply, communicating more crisply, and saving
everyone time. The core idea: adapt to how people actually consume content. People spend
26 seconds on average reading a piece of content. Most scan, not read. So every word must earn
its place.

The motto: **"Brevity is confidence. Length is fear."**

## When to Use This Skill

- User pastes text and wants it rewritten to be shorter/clearer/punchier
- User wants to apply Smart Brevity structure (tease → lede → why it matters → go deeper)
- User wants to improve a specific medium (email, newsletter, presentation, speech, social post, meeting agenda, website copy, UI copy, README, etc.)
- User wants to audit a codebase, website, or app for copy that could be improved
- User asks for help with any form of written communication and brevity would improve it

## Two Modes of Operation

### Mode 1: Rewrite Text

The user provides text. You rewrite it and present **numbered changes** for approval.

### Mode 2: Audit & Recommend

The user points you at a codebase, website, document, or app. You scan the copy,
identify text that violates Smart Brevity principles, and present **numbered recommendations**
for approval.

---

## How to Execute

### Step 1: Identify the Medium

Determine what kind of content the user is working with. If unclear, ask. The medium
determines which specific guidance applies. Read `mediums.md` for medium-specific rules.

Common mediums:
- **Email** — subject line (6 words), strong lede, "Why it matters," bullets
- **Newsletter** — numbered items, 200 words/item, 1,000 words total, "1 big thing" opener
- **Presentation** — 1 message/slide, 20 words/slide max, 5-6 slides, billboard test
- **Speech** — one Big Thought (15 words max), open with story, close with restatement
- **Social media** — platform-specific (Twitter=facts/data, Instagram=image+slim text, Facebook=provocative angle)
- **Meeting** — objective (1 sentence), agenda (3 bullets), 20-min default
- **General/other** — apply Core 4 structure universally

### Step 2: Analyze the Input

Read `principles.md` for the full rule set. Apply these checks:

1. **Tease/headline check**: Is it 6 words or fewer? Strong words? Active? Would you click it?
2. **Lede check**: Is the first sentence the most important thing? Is it one sentence? Direct?
3. **Context check**: Is there a "Why it matters" or equivalent Axiom? Does it add (not repeat)?
4. **Depth check**: Is there a "Go deeper" exit? Are bullets used for 3+ points?
5. **Word-level check**: Weak/foggy/fancy words? Passive voice? Jargon? Too many syllables?
6. **Structure check**: Paragraphs too long? Missing bold signposts? Wall of text?
7. **Length check**: Does it exceed targets for its medium?
8. **Audience check**: Is it audience-first or ego-first? Does it respect the reader's time?

### Step 3: Present Changes as a Numbered List

This is critical. Do NOT just rewrite everything silently. Present each change as a numbered item
so the user can approve or deny individually.

Format each change like this:

```
1. [CATEGORY] Brief description of the change
   BEFORE: "the original text"
   AFTER: "the rewritten text"
   WHY: one-sentence rationale

2. [CATEGORY] Brief description of the change
   BEFORE: "the original text"
   AFTER: "the rewritten text"
   WHY: one-sentence rationale
```

Categories to use:
- `[HEADLINE]` — tease/subject line changes
- `[LEDE]` — first sentence rewrites
- `[CONTEXT]` — adding/improving "Why it matters" or Axioms
- `[CUT]` — removing unnecessary words, sentences, or sections
- `[WORD]` — replacing weak/foggy/fancy words with strong ones
- `[STRUCTURE]` — reformatting (adding bullets, bold, breaking up paragraphs)
- `[VOICE]` — passive → active, formal → conversational
- `[LENGTH]` — trimming to meet medium-specific targets
- `[DEPTH]` — adding "Go deeper" or restructuring supporting detail

### Step 4: Wait for User Approval

After presenting the numbered list, tell the user:

> Reply with the numbers you want to apply (e.g., `1,3,5` or `1-4` or `all`), or `none` to skip.

### Step 5: Apply Approved Changes

Once the user replies:
- If they say `all` — apply every change and output the final rewritten text.
- If they give specific numbers (e.g., `1,3,6`) — apply only those changes and output the result.
- If they say `none` — do nothing.
- If they give feedback on specific items — revise those items and re-present.

When applying changes to a **codebase or file**, make the edits directly in the files.
When applying changes to **pasted text**, output the final rewritten version.

Always show a word count comparison: `BEFORE: X words → AFTER: Y words (Z% reduction)`

---

## Audit Mode (Codebase / Website / App)

When the user asks you to audit copy across files:

1. Scan the relevant files (UI strings, README, docs, marketing copy, error messages, tooltips, etc.)
2. Identify text that violates Smart Brevity principles
3. Group findings by file
4. Present as a numbered list (same format as above), with file paths
5. Wait for approval before making any edits

For code audits, focus on:
- UI-facing strings (buttons, labels, tooltips, error messages, onboarding copy)
- README and documentation files
- Marketing pages and landing page copy
- Email templates
- Notification text
- Comments that are excessively verbose (optional — only if user asks)

---

## Quick-Reference Checklist

Before presenting any rewrite, verify:

- [ ] Headline/subject: ≤6 strong words
- [ ] First sentence: one sentence, most important point, direct
- [ ] "Why it matters" or equivalent: present, adds context (not repetition)
- [ ] Bullets used for 3+ related points
- [ ] No passive voice
- [ ] No weak/foggy/fancy words (check against word lists in principles.md)
- [ ] Paragraphs: 2-3 sentences max
- [ ] Bold on key terms, Axioms, figures
- [ ] Within medium-specific length targets
- [ ] Audience-first, not ego-first
- [ ] Would YOU read this if you hadn't written it?

---

## Reference Files

- `principles.md` — Full Smart Brevity rule set (word choice, structure, formatting, anti-patterns). **Read this before any rewrite.**
- `examples.md` — Before/after examples from the book for calibration. Read when you need to calibrate tone and degree of change.
- `mediums.md` — Medium-specific guidance (email, newsletter, presentation, speech, social, meetings, visuals, inclusive writing). Read when the user specifies a medium.

---

## Tone of This Skill

When presenting changes, be direct. No preamble. No "Great question!" No throat-clearing.
Model the principles you're teaching. Your own output should exemplify Smart Brevity.
