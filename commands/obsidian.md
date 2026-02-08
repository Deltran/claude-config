---
description: Read, write, or organize notes in my Obsidian vaults
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls:*)
---

Manage my Obsidian vaults. User request: $ARGUMENTS

## Vault Location

All vaults live under `~/obsidian/` (symlink to `/mnt/c/Users/deltr/Documents/Obsidian/`).

### Vaults

| Vault | Path | Purpose |
|-------|------|---------|
| **pwaddingham** | `~/obsidian/pwaddingham/` | Primary personal vault — work notes, tech knowledge, hobbies, gaming |
| **3d printing** | `~/obsidian/3d printing/` | Focused vault for 3D printing resources |

### pwaddingham structure

```
Areas/
  3D Printing/       — printer/sculptor/STL notes
  Linux/             — CLI tools, setup guides
  OPR/               — OnePageRules tabletop gaming
  Painting/          — miniature painting techniques
Clippings/           — web clippings
Grimdark Future thoughts/ — army list theory
PacketViper/         — work notes (Areas/, Daily/, Projects/, Resources/)
Programming/         — language/tool notes
Random Game Knowledge/ — video game notes
Shhhh/               — secrets (gitignored, never read or write here)
```

## Rules

1. **Default vault is `pwaddingham`** unless the user specifies otherwise or the topic clearly belongs in `3d printing`.
2. **Match existing structure.** Before creating a new file, check what folders and files already exist nearby. Place notes where they logically fit.
3. **Use standard markdown.** Obsidian renders standard markdown. Use `# headings`, `- bullets`, `[[wiki links]]` for cross-references between notes, and `---` for frontmatter if needed.
4. **File naming.** Use Title Case for note filenames (e.g., `Filament Drying Times.md`). No special characters beyond spaces and hyphens.
5. **Never touch `Shhhh/`** — it contains secrets and is gitignored.
6. **Never touch `**/Resources/Accounts.md`** — it contains credentials and is gitignored.
7. **Auto-sync is handled.** A cron job runs every 5 minutes to commit and push changes. No need to manually git commit.
8. **When reading,** use Glob and Grep to find relevant notes, then Read to show contents.
9. **When writing,** confirm what you're creating/editing and where, then do it.
10. **When the user says "add a note about X"** without more detail, create a concise, useful note — not a stub.
