---
description: Write session state summaries periodically so that context compaction and vague resumption requests don't cause loss of orientation or wasted re-explanation.
---
# Session State Persistence Prevents Context Loss and Ambiguity

Two problems motivated this practice. First: context compaction. When the context window is compressed, raw conversation detail is lost — decisions, dead ends, current branch, what was in flight. Session state files written before compaction act as anchors that survive it. The next turn can read the file and reorient without the user having to re-explain anything.

Second: the user is sometimes non-specific when resuming ("continue with that" / "pick up where we left off"). Without a recent state file, that's genuinely ambiguous. With one, it's a fast lookup. The state file resolves the ambiguity by showing what was actually being worked on, in what state, and what was planned next.

The cadence: write after a significant milestone, roughly every 15-20 tool calls during active work, before a long chain of subagent dispatches, or when context is visibly growing large. Don't write on every tool call — that's noise. The format is intentionally terse (~100-200 tokens): branch, what I'm doing, key decisions, files touched, blockers, next step.

Timing inspiration came from OpenClaw's approach to periodic state saves as a recovery mechanism.
