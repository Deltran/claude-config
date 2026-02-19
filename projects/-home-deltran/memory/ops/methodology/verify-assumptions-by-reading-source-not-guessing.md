---
description: Before implementing or testing, list assumptions about how the system behaves, then validate them against actual source code — don't trust the mental model.
---
# Verify Assumptions by Reading Source, Not Guessing

Claude tends to pull API names, effect identifiers, and system behaviors from planning sessions or hallucinations rather than from the code itself. In the dorf project this surfaced repeatedly: effect names, engine hooks, and hero skill config keys were invented from context rather than read from the actual battle engine or skill config files. The answer was always already there in source.

The practice: before writing any implementation or test, explicitly list what you're assuming about the system — how it behaves, what it exposes, what the identifiers are — then check those assumptions against real source files. Don't trust memory of a planning session. Don't trust the mental model built from ideation. Read the code.

This catches wrong mental models before they compound. A single wrong assumption at the start can cascade: the implementation is built on it, tests are written around it, and by the time the error surfaces it has touched a dozen files. Reading source takes seconds; unwinding cascading assumptions can take hours.

The rule is simple: look before you build.
