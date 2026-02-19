---
description: After 2 failed attempts using the same approach, stop and try something structurally different. Don't burn context in a retry loop — the approach is wrong, not the execution.
---
# Two Failures Means Change Approach, Not Retry Harder

The failure mode: Claude hits an error, tweaks something minor, tries again, hits a similar error, tweaks again. Each iteration is slightly different but fundamentally the same strategy. The loop compounds — consuming context, burning time, and building false confidence that "one more try" will work because so much has already been invested in the approach.

The fix is a hard circuit breaker. Two failures using the same fundamental approach is a signal that the approach is wrong — not that the execution needs more refinement. At that point, stop. Step back. Assess what's actually happening, not what you expected to happen. Then try something structurally different: different entry point, different abstraction level, different tool, different framing of the problem.

If no alternative is obvious, that itself is useful information — it means the problem isn't well understood yet, and the right move is to surface that rather than continue grinding.

The sunk-cost trap is the enemy here. Time already spent on an approach is not a reason to keep spending more. Two failures is the line.
