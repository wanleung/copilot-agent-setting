# init-memory-bank Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `init-memory-bank` superpowers skill and an `install-skill.sh` script so users can populate a project's Memory Bank with real content in one guided session.

**Architecture:** Two files are added to `copilot-agent-setting`: the skill (`skills/init-memory-bank/SKILL.md`) containing step-by-step AI agent instructions, and `install-skill.sh` which copies any skill from `skills/*/` into the installed-plugins directory. No Python, no tests beyond shell verification.

**Tech Stack:** Bash (install script), Markdown (skill instructions), superpowers skill format (YAML frontmatter + Markdown body)

---

## File Map

| Action | Path | Purpose |
| --- | --- | --- |
| Create | `skills/init-memory-bank/SKILL.md` | Skill instructions the Copilot CLI agent follows |
| Create | `install-skill.sh` | Copies skills into the superpowers plugin directory |

---

### Task 1: Create the `init-memory-bank` SKILL.md

**Files:**

- Create: `skills/init-memory-bank/SKILL.md`

The skill is Markdown with YAML frontmatter. The AI agent reads it and executes using its built-in tools (`bash`, `ask_user`, file creation). Every step must be concrete — no vague instructions.

- [ ] **Step 1: Create the skills directory**

```bash
mkdir -p /home/wanleung/Projects/copilot-agent-setting/skills/init-memory-bank
```

Expected: directory created with no output.

- [ ] **Step 2: Create `skills/init-memory-bank/SKILL.md`**

Create the file at `skills/init-memory-bank/SKILL.md` with this exact content:

````markdown
---
name: init-memory-bank
description: Use when starting a new project to populate the Memory Bank with real project context. Scans existing files, asks 5 questions, and writes fully populated memory-bank/*.md files so Copilot CLI has useful context from session one.
---

# Init Memory Bank

**Announce at start:** "I'm using the init-memory-bank skill to set up your project's Memory Bank."

## Overview

Populate `memory-bank/*.md` files with real project content in a single guided session.
Three files are fully written; three are seeded as structured stubs.

---

## Step 1 — Scan Existing Files

Run these checks to infer stack and project name:

```bash
# Check for package files
[ -f package.json ] && cat package.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('name:', d.get('name',''), 'description:', d.get('description',''))"
[ -f pyproject.toml ] && head -10 pyproject.toml
[ -f requirements.txt ] && echo "Python project (requirements.txt)"
[ -f Cargo.toml ] && head -5 Cargo.toml
[ -f go.mod ] && head -3 go.mod
[ -f pubspec.yaml ] && head -10 pubspec.yaml
[ -f README.md ] && head -20 README.md
[ -f docker-compose.yml ] && echo "docker-compose.yml found"
[ -f Dockerfile ] && echo "Dockerfile found"
```

Summarise what you found in a single sentence before asking questions, e.g.:
> "I found `package.json` (Node.js project: my-app) and `docker-compose.yml`. I'll use these to pre-fill the tech stack. A few questions about the rest."

If `memory-bank/` does not exist, create it now with inline templates (see Step 3 below for exact file content — write empty versions first as placeholders, then overwrite in Step 3).

---

## Step 2 — Ask 5 Questions (one at a time, wait for each answer)

Ask these using `ask_user`. Wait for the answer before asking the next one.

**Q1 — Project name and goal:**
> "What is this project called, and what does it do in one sentence?"

**Q2 — User problem:**
> "What problem does this solve for users? Who are the target users?"

**Q3 — Core requirements:**
> "What are the 3–5 most important things this project must do? (List them)"

**Q4 — Tech stack:**
Show the detected stack from Step 1 and ask:
> "Here's what I detected: [summarise detected stack]. Does this look right, or would you like to correct/add anything?"

If nothing was detected, ask:
> "What's the tech stack? (language, framework, database, infrastructure)"

**Q5 — Git hook:**
> "Should I install the semi-auto git hook so the memory bank auto-updates after every commit? (Recommended for active projects)"
Provide choices: ["Yes, install the git hook (Recommended)", "No, skip for now"]

---

## Step 3 — Write the 6 Memory Bank Files

Use the answers from Step 2 to write the files below. Write all 6 files.
Replace every placeholder in `[brackets]` with real content from the answers.
If an answer was vague or skipped, use a sensible default and note "(fill in later)".

### 3a. `memory-bank/projectbrief.md` (fully populated)

```markdown
# Project Brief

> Read by AI agents at session start. Update when project goals or scope change.

## Project Name

[Q1 project name]

## Goals

[Q1 goal sentence]

## Core Requirements

[For each item from Q3, add a bullet: - Requirement]

## Scope

**In scope:**
[List the core requirements from Q3 as in-scope items]

**Out of scope:**
- Anything not listed in Core Requirements above

## Success Criteria

[Restate each core requirement from Q3 as a measurable outcome]
```

### 3b. `memory-bank/productContext.md` (fully populated)

```markdown
# Product Context

> Read by AI agents at session start. Update when user problem or UX goals change.

## Why This Project Exists

[Q2 problem statement]

## User Problems

[For each problem implied by Q2, add a bullet: - Problem]

## Target Users

[Q2 target users description]

## UX Goals

- [Infer 2 UX goals from Q2 answer, e.g. "Simple setup", "Clear feedback on errors"]

## Non-Goals

- This project does not cover anything outside its core requirements (see projectbrief.md)
```

### 3c. `memory-bank/techContext.md` (fully populated)

Use detected stack from Step 1 and confirmed/corrected answer from Q4.

Infer dev setup commands from detected files:
- `package.json` → `npm install` / `npm run dev`
- `requirements.txt` → `pip install -r requirements.txt`
- `pyproject.toml` → `pip install -e .`
- `Cargo.toml` → `cargo build`
- `go.mod` → `go mod download` / `go run .`
- `pubspec.yaml` → `flutter pub get`
- `docker-compose.yml` → `docker-compose up -d`

```markdown
# Tech Context

> Read by AI agents at session start. Update when stack or dependencies change.

## Tech Stack

| Layer | Technology | Version |
| --- | --- | --- |
[Row per technology detected/confirmed from Q4. Format: | Layer | Technology | Version or — |]

## Key Dependencies

[List key packages visible in detected files, one bullet per package with brief note]
[If nothing detected: - (fill in as dependencies are added)]

## Environment Requirements

- (fill in as environment variables are identified)

## Development Setup

```bash
[Inferred setup commands based on detected files]
```

## Deployment

[If docker-compose.yml detected: "Docker Compose — run `docker-compose up -d`"]
[Otherwise: "(fill in once deployment approach is decided)"]
```

### 3d. `memory-bank/systemPatterns.md` (seeded stub)

```markdown
# System Patterns

> Read by AI agents at session start. Update when architecture or key patterns change.

## Architecture Overview

[Q1 project name] is in early development. Architecture is being designed.
Fill in this section once the initial architecture is decided.

## Module Relationships

```text
(fill in once modules are defined)
```

## Key Design Patterns

- (fill in as patterns emerge)

## Important Conventions

- (fill in as team conventions are established)

## Known Gotchas

- (fill in as sharp edges are discovered)
```

### 3e. `memory-bank/activeContext.md` (seeded stub)

```markdown
# Active Context

> Updated automatically after each AI pipeline run and after manual sessions.

## Current Focus

Initial project setup for [Q1 project name].

## Recent Changes

- Memory Bank initialised with project context.

## Immediate Next Steps

1. Fill in `systemPatterns.md` once initial architecture is designed.
2. Begin implementing core requirements (see `projectbrief.md`).

## Open Questions

- Architecture approach for [Q1 project name] not yet decided.

## Last Updated

[today's date] — Memory Bank initialised via init-memory-bank skill.
```

### 3f. `memory-bank/progress.md` (seeded stub)

```markdown
# Progress

> Updated automatically after each AI pipeline run and after manual sessions.

## Done

- [x] Memory Bank initialised.

## In Progress

- [ ] Initial project setup.

## Blocked

(none)

## Known Issues / Tech Debt

(none yet)

## Upcoming

[For each core requirement from Q3, add a bullet: - Requirement]
```

---

## Step 4 — Optional: Install Git Hook

If Q5 was "Yes":

```bash
# Look for install-memory-bank-hook.sh in common locations
if [ -f ./install-memory-bank-hook.sh ]; then
    bash ./install-memory-bank-hook.sh .
elif [ -f "$HOME/Projects/copilot-agent-setting/install-memory-bank-hook.sh" ]; then
    bash "$HOME/Projects/copilot-agent-setting/install-memory-bank-hook.sh" .
else
    echo "install-memory-bank-hook.sh not found. Clone copilot-agent-setting and run it manually."
fi
```

If the hook install fails because this is not a git repo, note it in the summary and skip.

---

## Step 5 — Print Summary

Print this summary (substitute actual values):

```
✅ Memory Bank initialised for [Q1 project name]

Fully populated:
  memory-bank/projectbrief.md
  memory-bank/productContext.md
  memory-bank/techContext.md

Seeded (fill in as project evolves):
  memory-bank/systemPatterns.md  ← fill after architecture is designed
  memory-bank/activeContext.md
  memory-bank/progress.md

[✅ Git hook installed — bank will auto-update after every commit]
[⚠️  Git hook skipped — not a git repo or hook script not found]

Copilot CLI will read these files at the start of every session.
Run update-memory-bank.sh at any time to refresh the bank manually.
```

---

## Notes for the Agent

- Write files using the `create` or `edit` tools, not `echo` redirects.
- If a `memory-bank/*.md` file already exists with real content (not just the template placeholder text), **skip writing it** and note it was already populated.
- "Real content" means the file doesn't contain `[Project name here]` or `[What this project aims to achieve`.
- Today's date: use `date +%Y-%m-%d` in bash to get it.
````

- [ ] **Step 3: Verify the file exists and has correct frontmatter**

```bash
head -5 /home/wanleung/Projects/copilot-agent-setting/skills/init-memory-bank/SKILL.md
```

Expected output:
```
---
name: init-memory-bank
description: Use when starting a new project to populate...
---
```

---

### Task 2: Create `install-skill.sh`

**Files:**

- Create: `install-skill.sh`

- [ ] **Step 1: Create `install-skill.sh` at the repo root**

Create `/home/wanleung/Projects/copilot-agent-setting/install-skill.sh` with this content:

```bash
#!/usr/bin/env bash
# Usage: ./install-skill.sh
# Installs all skills from skills/ into the superpowers plugin directory.
# Safe to re-run after skill updates.
set -euo pipefail

DEST="$HOME/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$SCRIPT_DIR/skills" ]; then
    echo "Error: no skills/ directory found in $SCRIPT_DIR" >&2
    exit 1
fi

mkdir -p "$DEST"

installed=0
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    cp -r "$skill_dir" "$DEST/$name"
    echo "Installed: $name → $DEST/$name"
    installed=$((installed + 1))
done

if [ "$installed" -eq 0 ]; then
    echo "No skills found in $SCRIPT_DIR/skills/"
    exit 1
fi

echo ""
echo "Done. $installed skill(s) installed. Restart Copilot CLI to pick up new skills."
```

- [ ] **Step 2: Make `install-skill.sh` executable**

```bash
chmod +x /home/wanleung/Projects/copilot-agent-setting/install-skill.sh
```

- [ ] **Step 3: Run `install-skill.sh` and verify**

```bash
cd /home/wanleung/Projects/copilot-agent-setting && bash install-skill.sh
```

Expected output:
```
Installed: init-memory-bank → /home/wanleung/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills/init-memory-bank
Done. 1 skill(s) installed. Restart Copilot CLI to pick up new skills.
```

- [ ] **Step 4: Verify skill file was copied**

```bash
ls /home/wanleung/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills/init-memory-bank/
```

Expected: `SKILL.md`

---

### Task 3: Commit and Push

**Files:** `skills/init-memory-bank/SKILL.md`, `install-skill.sh`

- [ ] **Step 1: Stage and commit**

```bash
cd /home/wanleung/Projects/copilot-agent-setting
git add skills/ install-skill.sh
git commit -m "feat: add init-memory-bank skill and install-skill.sh

- skills/init-memory-bank/SKILL.md: guided 5-question setup flow
- install-skill.sh: copies skills/ into superpowers plugin directory

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

- [ ] **Step 2: Push to remote**

```bash
cd /home/wanleung/Projects/copilot-agent-setting && git push origin master
```

Expected: push succeeds, remote shows new commit.

- [ ] **Step 3: Verify the skill is listed**

```bash
ls /home/wanleung/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills/ | sort
```

Expected: `init-memory-bank` appears in the list alongside existing skills.
