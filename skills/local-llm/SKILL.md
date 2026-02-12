---
name: local-llm
description: Use when starting work sessions or tasks that could benefit from local LLM delegation. Checks availability, asks about gaming status, and primes active delegation of simple subtasks to Qwen.
---

# Local LLM Delegation Reminder

## Purpose

Activate local LLM delegation mode. Check if the local Qwen model is available and actively look for subtasks to offload during this session.

## Steps

### 1. Check Ollama Status

Run this check silently:

```bash
curl -s --max-time 2 http://localhost:11434/api/tags | python3 -c "import sys,json; tags=json.load(sys.stdin); models=[m['name'] for m in tags.get('models',[])]; print('READY: ' + ', '.join(models)) if models else print('NO MODELS')" 2>/dev/null || echo "OFFLINE"
```

### 2. Handle Status

- **OFFLINE**: Report that ollama isn't running. Offer: "Want me to skip local delegation this session, or should you start ollama (`ollama serve`)?"
- **NO MODELS**: Report ollama is running but no models loaded. Suggest `ollama pull qwen3-coder`.
- **READY**: Proceed to step 3.

### 3. Ask the User

Use AskUserQuestion with these options:

- **Normal mode** — Delegate simple subtasks when it's a clear win (default behavior from memory instructions)
- **Aggressive mode** — Conserve Claude usage. Delegate anything Qwen can handle, as long as the delegation overhead (prompt + parsing output) doesn't cost more tokens than just doing it directly
- **Gaming / off** — Zero local LLM usage this session. GPU is yours.

### 4. Confirm Mode

**Normal mode:**
> Local LLM delegation is **on (normal)**. I'll delegate obvious wins — boilerplate, format conversions, regex, test stubs, summaries, repetitive codegen. I'll review all output before applying.

**Aggressive mode:**
> Local LLM delegation is **on (aggressive)**. I'm conserving your Claude usage. I'll push as much work to Qwen as I reasonably can — anything where the delegation round-trip is cheaper than me generating the answer directly. I'll still review output and won't delegate things Qwen will get wrong.

**Gaming / off:**
> Local LLM delegation is **off** for this session. All work stays on Claude API — your GPU is yours.

## Delegation Reference

### Normal mode — delegate freely
- Generating boilerplate / repetitive code
- Summarizing files or text
- Simple refactors (rename, format conversion)
- Writing test stubs
- JSON/YAML/TOML conversions
- Regex generation
- Commit message drafts

### Aggressive mode — also delegate these
Everything from normal mode, plus:
- Writing whole functions from clear specs (e.g. "write a debounce function in JS")
- Generating TypeScript interfaces / types from examples
- CSS/styling tasks with clear requirements
- Documentation strings and comments
- Shell script snippets
- Data transformations and mappings
- Error message copy
- Config file generation (eslint, tsconfig, etc.)
- Generating mock data / fixtures
- Explaining code snippets (read file yourself, send snippet to Qwen for summary)

### Aggressive mode — delegation cost test
Before each delegation, do a quick mental check:
1. **Prompt overhead**: How many tokens will I spend writing the prompt to Qwen + parsing its response?
2. **Direct cost**: How many tokens would it take me to just produce the answer inline?
3. **Delegate only if** prompt + parse < direct output. If it's close, just do it yourself.

Examples:
- "Generate 20 lines of mock user data" — delegate (short prompt, long output saved)
- "Rename `x` to `count`" — don't delegate (faster to just do it)
- "Write a 50-line utility function from a clear spec" — delegate (big output savings)
- "Fix a one-line typo" — don't delegate (zero savings)

### Never delegate (any mode)
- Anything requiring full codebase context
- Architectural decisions
- Complex multi-file refactors
- Security-sensitive code
- Anything where correctness is critical without review

### How to call

```bash
# Quick generation
curl -s http://localhost:11434/api/generate -d '{
  "model": "qwen3-coder",
  "prompt": "YOUR PROMPT HERE",
  "stream": false,
  "options": {"num_predict": 500}
}' | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])"

# Or use the CLI tool
~/code/scripts/ask-qwen "YOUR PROMPT HERE"
~/code/scripts/ask-qwen -n 500 "YOUR PROMPT HERE"
```

### Rules
- Always review Qwen's output before using it
- Keep prompts short and specific
- Use `num_predict` / `-n` to limit response length
- If a delegation fails or returns garbage, just do it yourself — don't retry
