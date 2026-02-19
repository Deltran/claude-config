---
description: Captures unresolved conflicts between competing workflow rules or preferences. Triggers /rethink at threshold for resolution.
---
# Tensions

Capture cases where two rules, preferences, or patterns conflict with each other.

## Format

Each tension is a separate .md file with a prose-sentence filename:
- `context-protection-vs-inline-debugging-need.md`
- `sonnet-for-coding-but-needs-opus-reasoning.md`

File contents: 2-5 sentences describing the two sides of the tension and why it hasn't been resolved yet.

## Lifecycle

- Created when a conflict between instructions is noticed
- Reviewed during `/rethink` sessions (triggered when count >= 5)
- After review: resolved into an updated rule, or kept with a documented tradeoff
