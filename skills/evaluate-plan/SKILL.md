---
name: evaluate-plan
description: Use when evaluating a development plan against original requirements, specs, or design criteria — scores adherence per-criterion and overall, then proposes targeted improvements to close gaps
---

# Evaluate Plan

## Overview

Systematically evaluate a development plan against its original request or specification. Extract discrete criteria from the source of truth, score each against the plan, and propose improvements to reach 100.

## When to Use

- A plan has been written and needs validation before implementation
- You want to check if a plan drifted from the original ask
- Reviewing your own plan before presenting it to the user
- User asks "does this plan cover everything?"

## Source of Truth

Locate the original requirements in priority order:

1. **User's explicit request** in the current conversation
2. **Planning/spec files** in `docs/plans/` or project root
3. **Memory files** in the auto-memory directory (`.claude/projects/*/memory/`)
4. **CLAUDE.md** project instructions (for design constraints and conventions)

If multiple sources exist, reconcile them — flag contradictions rather than silently picking one.

## Method

### Step 1: Extract Criteria

Read the original request and decompose it into discrete, testable criteria. Each criterion should be:
- **Atomic** — one concern per criterion
- **Verifiable** — you can point to plan text that addresses it or doesn't
- **Labeled** by category: `[Functional]`, `[Constraint]`, `[UX]`, `[Technical]`, `[Performance]`, `[Design]`

Number every criterion for reference.

### Step 2: Match Criteria to Plan

For each criterion, find the corresponding plan element(s). Three outcomes:
- **Covered** — plan explicitly addresses it
- **Partially covered** — plan touches it but incompletely or ambiguously
- **Missing** — plan doesn't address it at all

Quote the specific plan text that covers (or fails to cover) each criterion.

### Step 3: Score

**Per-criterion scoring:**
| Score | Meaning |
|-------|---------|
| 100 | Fully addressed, no gaps |
| 75 | Addressed but with minor ambiguity or missing detail |
| 50 | Partially addressed, significant gaps |
| 25 | Mentioned but not meaningfully addressed |
| 0 | Not addressed at all |

**Overall score:** Weighted average. Functional and Constraint criteria weigh 2x. Others weigh 1x.

Be honest and strict. A plan that waves at a requirement without specifying how gets 25-50, not 75.

### Step 4: Propose Improvements

For every criterion scoring below 100, propose a specific, actionable improvement:
- What to add, change, or clarify in the plan
- Why it closes the gap
- Expected score after the fix

Group improvements by impact: high-impact fixes first (those that move multiple criteria or fix large gaps).

## Output Format

```
## Plan Evaluation: [Plan Name or Summary]

### Source of Truth
[Where you found the original requirements — file path, conversation context, etc.]

### Extracted Criteria

| # | Category | Criterion | Score | Status |
|---|----------|-----------|-------|--------|
| 1 | [Functional] | ... | 85 | Covered |
| 2 | [Constraint] | ... | 50 | Partial |
| 3 | [UX] | ... | 0 | Missing |

### Overall Score: XX/100

### Criterion Details

#### #1: [Criterion name] — Score: XX
**Source requirement:** [Quote from original request]
**Plan coverage:** [Quote from plan or "Not addressed"]
**Gap:** [What's missing, if anything]

[Repeat for each criterion]

### Proposed Improvements (ordered by impact)

1. **[Improvement title]** — Fixes #3, #7 (+XX points)
   [Specific change to make in the plan]

2. **[Improvement title]** — Fixes #2 (+XX points)
   [Specific change to make in the plan]

### Projected Score After Improvements: XX/100
```

## Scoring Discipline

- **Don't grade on a curve.** A missing requirement is 0 even if everything else is great.
- **Don't infer intent.** If the plan doesn't say it, it doesn't get credit for probably meaning it.
- **Don't conflate quality with coverage.** A well-written plan that misses half the requirements scores low.
- **Flag scope creep.** Plan elements that address things NOT in the original request get noted separately — they're not bad, but they don't earn points.

## Common Mistakes

- **Criteria too coarse:** "Implement the feature" is not a criterion. Break it down.
- **Generous scoring:** Giving 75 for vague hand-waving. Be strict — quote evidence.
- **Missing constraints:** Original requests often embed constraints implicitly ("must work on mobile" buried in context). Extract these.
- **Ignoring non-functional requirements:** Performance, UX, accessibility, and design constraints are criteria too.
