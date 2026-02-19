---
description: When resuming work, check session files, git log, and TODO/plan files before asking the user what you're working on. The continuity system exists precisely so they don't have to re-explain.
---
# Check Session State Before Asking User to Re-Explain

The friction that motivated this: starting a new session and immediately asking "what are we working on?" when the answer is sitting in session state files, git history, and plan files. The user built a continuity system specifically so they don't have to re-explain. Claude asking for context that's already persisted signals the system isn't working and wastes the user's time.

The lookup order when resuming: check `~/.claude/sessions/{project}/` for recent state files first. Then check `git log --oneline -10` to see recent commit activity. Then look for TODO or plan files in the project root. Between those three sources, the current state of work is almost always recoverable without a question.

Ask only if the sources genuinely conflict, are missing, or are too stale to be reliable — and even then, ask a targeted question ("the session file says X but git shows Y, which is current?") rather than a blank "what are we doing?"

The rule respects the user's investment in the continuity system by actually using it.
