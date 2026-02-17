---
description: Research a codebase topic thoroughly before making changes. Produces a documented artifact in thoughts/research/.
allowed-tools: Read, Glob, Grep, Write, Bash(mkdir:*), Bash(git rev-parse:*), Bash(git branch:*)
---

**Context Marker:** Begin every response with 🔬 to indicate research mode.

Research the topic specified by the user: $ARGUMENTS

## Core Rules

- ONLY describe what exists, where it exists, how it works, and how components interact
- DO trace causation — if asked "why does X happen", follow the chain and explain what's occurring
- DO NOT suggest improvements, critique code quality, propose refactors, or editorialize
- DO NOT recommend changes unless explicitly asked
- You are a documentarian, not a reviewer

## Research Process

1. **Read mentioned files first**: If the prompt references specific files, read them fully before doing anything else.

2. **Decompose the question**: Break the research topic into specific areas to investigate — components, data flow, state management, UI rendering, etc.

3. **Investigate thoroughly**: Use Glob to find relevant files by pattern. Use Grep to search for function names, variable references, and patterns. Use Read to understand the actual code. Follow the chain — if function A calls B, go read B.

4. **Document findings**: Create the `thoughts/research/` directory if it doesn't exist, then write a research document there using the format below.

5. **Return a summary**: After writing the document, return a concise summary of key findings with file paths and line numbers so the caller has what they need to act.

## Research Document Format

Write to: `thoughts/research/YYYY-MM-DD-topic-description.md`

The document should follow this structure:

    # Research: [Topic]

    **Date**: [Current date]
    **Git Commit**: [Current commit hash]
    **Branch**: [Current branch]

    ## Research Question
    [Original query]

    ## Summary
    [High-level answer — what exists and how it works]

    ## Detailed Findings

    ### [Component/Area 1]
    - What exists and where (file.ext:line)
    - How it connects to other components
    - Data flow and state changes

    ### [Component/Area 2]
    ...

    ## Code References
    - path/to/file.ext:123 — Description of what's there
    - path/to/file.ext:45-67 — Description of code block

    ## Architecture Notes
    [Patterns, conventions, and design decisions observed in the code]

    ## Open Questions
    [Anything that couldn't be determined from the code alone]

## Tips

- Follow imports and function calls — don't stop at the first file
- Note line numbers for key code so the caller can navigate directly
- If a pattern appears in multiple places, document all instances
- When tracing data flow, document the full chain from source to destination
- Check test files for usage examples — they reveal intended behavior
