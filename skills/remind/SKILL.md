---
name: remind
description: Capture action items to your work inbox for resurfacing in morning briefings. Supports add, list, and done operations.
user_invocable: true
---

# /remind — Work Inbox

Manages `~/.claude/work-inbox.md`, a simple timestamped action item list that gets surfaced by the startup hook.

## Usage

- `/remind <text>` — Add a new item
- `/remind list` — Show all pending items
- `/remind done <number>` — Mark item as done (moves to done section)
- `/remind clear-done` — Remove completed items from the file

## Behavior

### Adding an item (`/remind <text>` or no recognized subcommand)

1. Read `~/.claude/work-inbox.md` (create if missing)
2. Append under `## Pending` section:
   ```
   - [ ] **{YYYY-MM-DD HH:MM}** — {text}
   ```
3. Confirm: "Added to work inbox: {text}"

### Listing items (`/remind list`)

1. Read `~/.claude/work-inbox.md`
2. Display all pending items with line numbers
3. If empty, say "Work inbox is empty"

### Completing an item (`/remind done <number>`)

1. Read the file
2. Move item #N from `## Pending` to `## Done` section, changing `- [ ]` to `- [x]`
3. Confirm which item was completed

### Clearing done items (`/remind clear-done`)

1. Remove all items under `## Done`
2. Confirm count removed

## File Format

The file `~/.claude/work-inbox.md` should look like:

```markdown
# Work Inbox

## Pending
- [ ] **2026-02-17 10:30** — Check traffic-by-county load time
- [ ] **2026-02-17 11:00** — Revisit item drop tables

## Done
- [x] **2026-02-16 14:00** — Fix blacksmith unlock gate
```

## Implementation Notes

- Use the Read tool to check if the file exists, Write/Edit to modify it
- When creating the file fresh, include both `## Pending` and `## Done` headers
- Item numbers in `done` command are 1-indexed based on display order in Pending section
- Keep it simple — this is a flat text file, not a database
