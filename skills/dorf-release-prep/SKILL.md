---
name: dorf-release-prep
description: Bump version and generate player-friendly changelog from git history. Use when ready to cut a new release.
user_invocable: true
---

# Dorf Release Prep

## Overview

Prepare a new release by reading git changes, generating a player-friendly changelog, bumping the version, and updating all version/changelog files.

## Steps

### 1. Read current version

Read `src/config.js` to get the current `APP_VERSION`.

### 2. Get git changes since last version bump

Run this to find commits since the last version bump:

```bash
git log --oneline $(git log --all --oneline --grep="APP_VERSION" --diff-filter=M -- src/config.js | head -1 | cut -d' ' -f1)..HEAD
```

If that fails (e.g., first release), fall back to:

```bash
git log --oneline -20
```

Also run `git diff --stat` against the same range to understand scope of changes.

### 3. Determine version bump

Based on the changes, suggest a version bump:
- **patch** (0.0.x): Bug fixes, UI tweaks, small adjustments
- **minor** (0.x.0): New features, new heroes, new mechanics, new content
- **major** (x.0.0): Major overhauls, breaking save changes, huge milestones

Present your suggestion to the user with the reasoning and let them confirm or override using AskUserQuestion. Show the proposed new version number.

### 4. Draft changelog entries

Write concise, player-friendly changelog entries. These are for gamers, not developers.

**Tone rules:**
- Write like patch notes a player would actually read
- Lead with what's fun/new/exciting, not technical details
- Use present tense ("Adds", "Fixes", not "Added", "Fixed")
- No jargon — "battle animations" not "CSS keyframe refactor"
- Group related changes into single bullets when it makes sense
- Keep it short — aim for 3-8 bullets max

**Good examples:**
- `- New hero: Korrath Hollow Ear (5-star Ranger)`
- `- Boss enemies now have dramatic entrance animations`
- `- Fixes a bug where buffs could stack infinitely`
- `- Battle transitions feel smoother and more cinematic`

**Bad examples (too technical):**
- `- Refactored applyEffect to support maxStacks property`
- `- Added CSS keyframe animation for .enemy-wrapper`
- `- Fixed race condition in battle store initialization`

Present the draft to the user and let them confirm or request edits using AskUserQuestion.

### 5. Update files

Once the user approves, update these three files:

1. **`src/config.js`** — Update the `APP_VERSION` string
2. **`version.txt`** — Replace contents with just the new version string
3. **`changelog.txt`** — Prepend the new version block at the TOP of the file, followed by a blank line, then the existing content. Format:

```
X.Y.Z
- First change
- Second change

[previous entries below]
```

### 6. Confirm

Show the user a summary of what was updated and remind them of the remaining release steps:
- Build the APK
- Upload APK to Google Drive (overwrite existing)
- Commit and push (so `version.txt` and `changelog.txt` are live on GitHub for the update checker)
