---
name: implementing-design-docs
description: Use when implementing a design document, spec, or feature brief that requires planning, parallel agent work, TDD, code review gates, and compliance verification against the original requirements
---

**Context Marker:** Begin every response with 🔨 to indicate implementation mode.

# Implementing Design Docs

## Overview

Orchestrate parallel agents to implement a design document. Delegate all code generation and heavy analysis to subagents — keep the main conversation focused on coordination and decisions.

**Core principle:** Never assume. Never ship without verification. Parallelize everything you can.

## When to Use

- User provides a design doc, spec, or feature brief and wants it implemented
- A task requires multi-phase development with review checkpoints
- Implementation spans multiple files or components that can be built concurrently

**When NOT to use:**
- Single-file changes or quick fixes
- Exploratory prototyping where the design is still forming
- Tasks where the user has given exact, line-by-line instructions

## Inputs

The user will provide a design document (file path, pasted content, or reference). If no design doc is provided, ask for one before proceeding.

## Phase 1: Planning

1. Invoke `/superpowers:writing-plans` to produce an implementation plan from the design doc.
2. Invoke `/superpowers:dispatching-parallel-agents` to identify which tasks can run concurrently.
3. Search the project for a style guide or contributing doc (e.g., STYLEGUIDE.md, CONTRIBUTING.md, .editorconfig, linter configs). If one exists, use it as the style authority. If none exists, infer conventions from the existing codebase.

### Before finalizing the plan, verify your understanding:

- **Do not act on assumptions.** If something in the design doc is ambiguous or underspecified, ask the user — even if you have a reasonable guess. You can share your best guess as context, but get confirmation before building on it.
- **You don't need to have a suggestion to ask a question.** If something is confusing, just surface the confusion and ask for guidance.
- **Seek clarification when multiple reasonable implementations exist.** If a requirement could be built two or more plausible ways, present the tradeoffs and let the user choose.
- **Surface inconsistencies.** If the design doc contradicts itself, or if a requirement conflicts with an existing codebase pattern, flag it explicitly.
- **Push back gently on questionable technical decisions.** If the design doc specifies an approach that seems like a poor fit (wrong tool, unnecessary complexity, performance concern), say so with your reasoning. Defer to the user's final call.

### Red Flags — STOP and ask the user:

- You're about to "assume" a resolution to a contradiction
- You're choosing between approaches without presenting tradeoffs
- A requirement feels technically unsound but you're going along with it
- You've written an "Assumed Resolutions" section instead of asking questions

**All of these mean: pause and ask. Do not resolve ambiguity yourself.**

## Phase 2: Implementation

- Fan out independent tasks to parallel subagents. Each subagent must:
  - Follow TDD (`/superpowers:test-driven-development`) — tests before implementation.
  - Adhere to the project style guide if one was found, otherwise match existing code conventions.
  - **Self-critique before reporting done.** Before handing off, switch from builder to critic: review your own code for cut corners, fragile assumptions, skipped edge cases, and hardcoded values that should be configurable. Fix what you find. The builder knows where the bodies are buried — use that.
- After each parallel batch completes, run a code review agent (subagent_type: `superpowers:code-reviewer`) that checks:
  - **Correctness** — does the code do what the plan says?
  - **Style** — does it match the project's style guide or established conventions?
  - If the reviewer flags issues, fix them before starting the next batch.
- Cap inter-phase review iterations at 3. If issues persist after 3 rounds, surface them to the user.

## Phase 3: Verification & Final Review

1. Run the full test suite. All tests must pass.
2. Launch a compliance review agent that compares the complete implementation against the original design doc. It must:
   - List each design requirement
   - Rate each as: fully addressed, partially addressed, or missing
   - Produce a compliance score: (fully addressed / total requirements) * 100
   - Flag any optimization opportunities or cleanup worth doing
3. If the compliance score is below 90, create a remediation plan targeting partially addressed and missing requirements. Re-verify after each remediation.
4. Apply any optimization or cleanup recommendations flagged by the compliance review.
5. Run the test suite one final time to confirm nothing regressed.
6. Cap remediation cycles at 3. If the score remains below 90, present the outstanding gaps to the user with your assessment and ask how to proceed.

## Completion Criteria

All three must be true:
- Green test suite
- Compliance score of 90 or above (confirmed by compliance review)
- Optimizations from final review applied and verified

If you cannot meet these criteria after exhausting remediation attempts, report what's unresolved and let the user decide.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Assuming resolutions to ambiguities instead of asking | Stop. Present the ambiguity and your best guess. Ask the user to confirm. |
| Writing implementation before tests | Delete it. Write the test first. TDD is not optional. |
| Working sequentially when tasks are independent | Use parallel subagents. Default to parallel, fall back to sequential only when there are real dependencies. |
| Subagent reports "done" without self-critiquing | The builder-as-critic step is not optional. Builders catch things cold reviewers miss. |
| Skipping compliance scoring at the end | Always run the compliance agent. A passing test suite does not prove design requirements are met. |
| No iteration cap on review/remediation loops | 3 rounds max, then escalate to the user. |
