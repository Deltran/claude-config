---
description: Why the memory system adopts patterns only when friction demands it -- premature adoption of theoretical improvements adds complexity without proven value. The pipeline is document -> skill -> hook.
---
# Friction-Driven Adoption Prevents Premature Optimization

The Ars Contexta analysis describes many patterns for AI memory systems. We don't adopt them all at once. The adoption rule: implement a pattern when accumulated friction makes the need undeniable, not because the pattern looks theoretically good.

The hardening pipeline is: **document -> skill -> hook**. A new practice starts as a written convention (in MEMORY.md or a methodology note). If it proves useful and gets used repeatedly, it becomes a skill (slash command). If it becomes truly automatic and rule-based, it becomes a hook (load-history.sh or similar). Each stage requires evidence that the previous stage created real value.

This prevents the system from accumulating clever-but-unused infrastructure. Every piece of the current system exists because something was painful enough to fix, not because it was architecturally elegant to add.
