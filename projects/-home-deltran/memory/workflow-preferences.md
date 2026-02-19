---
description: Rules for when to use subagents vs inline work, which model tier to use for each task type, and how to prompt research/debug agents effectively.
---
# Workflow Preferences

## Context Window Protection

User is deliberately protective of the main context window. Treat it as a scarce resource.

### Do inline (main context):
- Quick file reads to inform discussion
- Trivial one-liner edits
- Simple git operations
- Conversation about approach/architecture
- Orchestrating agent work

### Delegate to agents:
- Multi-file implementations
- Research and codebase exploration
- Debugging investigations
- Any task that might take multiple rounds of trial-and-error
- Writing new features or substantial code changes

### Model Strategy:
- **Opus** for main chat — orchestration, decisions, conversation
- **Opus** for debugging/investigation agents — tracing runtime behavior, multi-hop reasoning, diagnosing bugs
- **Sonnet** for coding agents — implementations, TDD, bug fixes with clear specs
- **Sonnet** for code-location research — "find the file that does X", simple lookups
- Spin up agents with `model: "sonnet"` by default for coding work
- Use `model: "opus"` when the agent needs to **reason about behavior**, not just locate code

### Agent Prompting for Research/Debug:
- Include known-good facts as constraints ("The user confirms X works. Don't re-investigate X.")
- State the user's actual observation up front so the agent can't contradict it
- For debugging: describe the symptom, what's confirmed working, and where to focus
- Don't let agents re-derive things the user has already verified

### Execution Preferences:
- **Always prefer subagent-driven execution** (option 1) over parallel/separate session
- **Always use a git worktree** for plan-based work (95%+ of the time — only skip if user says otherwise)
- **Suggest context clear before execution** — after plan is finalized and saved, recommend user `/clear` before starting subagent-driven execution so agents get a clean context window. The plan file persists so we pick right back up.

### Rationale:
- Main window = steering wheel for the session
- Heavy coding burns context fast
- Agent overhead is worth it for anything non-trivial
- Agent results still cost context, but it shifts the balance toward orchestration over raw code
- Sonnet conserves weekly usage while still delivering quality on well-specified tasks
