---
name: init-memory-bank
description: Use when starting a new project to populate the Memory Bank with real project context. Scans existing files, asks 5 questions, and writes fully populated memory-bank/*.md files so Copilot CLI has useful context from session one.
---

# Init Memory Bank

## Overview

This skill initialises a project's Memory Bank by scanning existing files, gathering key context from the user, and writing 6 fully populated (or seeded) Markdown files into `memory-bank/`.

**Announce at start:** "I'm using the init-memory-bank skill to set up your project's Memory Bank."

---

## Step 1 — Scan Existing Files

Run the following bash checks to detect the project's stack and context. Execute each command and note what is found:

```bash
# Node.js
if [ -f package.json ]; then
  python3 -c "import json,sys; d=json.load(open('package.json')); print('package.json: name=' + str(d.get('name','')) + ', description=' + str(d.get('description','')))"
fi

# Python (pyproject.toml)
if [ -f pyproject.toml ]; then head -10 pyproject.toml; fi

# Python (requirements.txt)
if [ -f requirements.txt ]; then echo "requirements.txt found"; fi

# Rust
if [ -f Cargo.toml ]; then head -5 Cargo.toml; fi

# Go
if [ -f go.mod ]; then head -3 go.mod; fi

# Flutter/Dart
if [ -f pubspec.yaml ]; then head -10 pubspec.yaml; fi

# README
if [ -f README.md ]; then head -20 README.md; fi

# Docker
if [ -f docker-compose.yml ]; then echo "docker-compose.yml found"; fi
if [ -f Dockerfile ]; then echo "Dockerfile found"; fi
```

After running the checks, **summarise what was found in one sentence** before proceeding to questions. For example: "I detected a Node.js project with a README, no Docker files."

**If `memory-bank/` does not exist:**

Create the directory and write empty placeholder files for all 6 files now (they will be overwritten in Step 3):

```bash
mkdir -p memory-bank
touch memory-bank/projectbrief.md
touch memory-bank/productContext.md
touch memory-bank/techContext.md
touch memory-bank/systemPatterns.md
touch memory-bank/activeContext.md
touch memory-bank/progress.md
```

---

## Step 2 — Ask 5 Questions (one at a time)

Use `ask_user` for each question. Wait for the answer before asking the next.

**Q1:** "What is this project called, and what does it do in one sentence?"
*(freeform — capture project name and one-sentence goal)*

**Q2:** "What problem does this solve for users? Who are the target users?"
*(freeform — capture problem statement and audience)*

**Q3:** "What are the 3–5 most important things this project must do? (List them)"
*(freeform — capture core requirements as bullet list)*

**Q4:** Show the detected stack from Step 1, then ask:
- If anything was detected: "Here's what I detected: [detected stack summary]. Does this look right, or would you like to correct/add anything?"
- If nothing detected: "What's the tech stack? (language, framework, database, infrastructure)"
*(freeform — verify or collect stack details)*

**Q5:** "Should I install the semi-auto git hook so the memory bank auto-updates after every commit?"

Provide choices:
- "Yes, install the git hook (Recommended)"
- "No, skip for now"

---

## Step 3 — Write 6 Memory Bank Files

Use the `create` or `edit` tools to write each file. Do **not** use echo redirects.

**Before writing each file:** check whether `memory-bank/<file>.md` already has real content. If the file does **not** contain the placeholder strings `[Project name here]` or `[What this project aims to achieve]`, skip it and note it was already populated.

Get today's date first:

```bash
date +%Y-%m-%d
```

---

### 3a. `memory-bank/projectbrief.md` — FULLY POPULATED

Write this file with all `[brackets]` replaced by real answers from Q1 and Q3. No placeholder brackets should remain.

```markdown
# Project Brief

> Read by AI agents at session start. Update when project goals or scope change.

## Project Name

[Q1 project name]

## Goals

[Q1 goal sentence]

## Core Requirements

[For each item from Q3, a bullet point — e.g.:
- Requirement one
- Requirement two
- Requirement three]

## Scope

**In scope:**
[Each core requirement from Q3 listed as an in-scope item]

**Out of scope:**
- Anything not listed in Core Requirements above

## Success Criteria

[Each core requirement from Q3 restated as a measurable outcome — e.g.:
- Users can do X with no errors
- Feature Y is implemented and tested]
```

---

### 3b. `memory-bank/productContext.md` — FULLY POPULATED

Write this file with all `[brackets]` replaced by real answers from Q2. No placeholder brackets should remain.

```markdown
# Product Context

> Read by AI agents at session start. Update when user problem or UX goals change.

## Why This Project Exists

[Q2 problem statement]

## User Problems

[Bullets for each problem identified in Q2 — e.g.:
- Problem one
- Problem two]

## Target Users

[Q2 target users description]

## UX Goals

- [Infer UX goal 1 from Q2 answers]
- [Infer UX goal 2 from Q2 answers]

## Non-Goals

- This project does not cover anything outside its core requirements (see projectbrief.md)
```

---

### 3c. `memory-bank/techContext.md` — FULLY POPULATED

Infer dev setup commands from detected files:

| Detected file | Setup command | Run command |
|---|---|---|
| `package.json` | `npm install` | `npm run dev` |
| `requirements.txt` | `pip install -r requirements.txt` | *(fill in)* |
| `pyproject.toml` | `pip install -e .` | *(fill in)* |
| `Cargo.toml` | `cargo build` | `cargo run` |
| `go.mod` | `go mod download` | `go run .` |
| `pubspec.yaml` | `flutter pub get` | `flutter run` |
| `docker-compose.yml` | `docker-compose up -d` | *(running via compose)* |

Use an aligned table for the tech stack. Replace all `[brackets]` with real values from Q4.

```markdown
# Tech Context

> Read by AI agents at session start. Update when stack or dependencies change.

## Tech Stack

| Layer | Technology | Version |
| --- | --- | --- |
[One row per layer detected or provided in Q4 — e.g.:
| Language | TypeScript | 5.x |
| Runtime | Node.js | 20.x |
| Framework | Express | 4.x |
| Database | PostgreSQL | 15 |]

## Key Dependencies

[List key dependencies from detected files, or "(fill in as dependencies are added)" if none detected]

## Environment Requirements

- (fill in as environment variables are identified)

## Development Setup

```bash
[Inferred commands from detected project files — e.g.:
npm install
npm run dev]
```

## Deployment

[If docker-compose.yml detected: "Docker Compose — run `docker-compose up -d`"]
[Otherwise: "(fill in once deployment approach is decided)"]
```

---

### 3d. `memory-bank/systemPatterns.md` — SEEDED STUB

Insert Q1 project name. Mark remaining sections for later. No other brackets to fill.

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

---

### 3e. `memory-bank/activeContext.md` — SEEDED STUB

Insert Q1 project name and today's date (from `date +%Y-%m-%d`).

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

[today's date from `date +%Y-%m-%d`] — Memory Bank initialised via init-memory-bank skill.
```

---

### 3f. `memory-bank/progress.md` — SEEDED STUB

Insert one bullet per core requirement from Q3 in the Upcoming section.

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

[One bullet per core requirement from Q3 — e.g.:
- [ ] Implement requirement one
- [ ] Implement requirement two
- [ ] Implement requirement three]
```

---

## Step 4 — Optional: Install Git Hook

**Only run this step if the user answered "Yes" to Q5.**

```bash
if [ -f ./install-memory-bank-hook.sh ]; then
    bash ./install-memory-bank-hook.sh .
elif [ -f "$HOME/Projects/copilot-agent-setting/install-memory-bank-hook.sh" ]; then
    bash "$HOME/Projects/copilot-agent-setting/install-memory-bank-hook.sh" .
else
    echo "install-memory-bank-hook.sh not found. Clone copilot-agent-setting and run it manually."
fi
```

If the hook install fails because the directory is not a git repo, skip silently and note it in the summary.

---

## Step 5 — Print Summary

Print this summary after all files are written:

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

Include only the relevant git hook line (installed or skipped, not both).

---

## Notes for the Agent

- **Write files using `create` or `edit` tools, not echo redirects or heredocs.**
- Before writing each `memory-bank/*.md` file, check if it already has real content:
  - If the file does **not** contain `[Project name here]` or `[What this project aims to achieve]`, skip it and note "already populated" in the summary.
- Get today's date with `date +%Y-%m-%d` before writing `activeContext.md`.
- The 3 "fully populated" files (`projectbrief.md`, `productContext.md`, `techContext.md`) must have **no `[bracket]` placeholders remaining** — replace every bracket with real user-provided content.
- The 3 "seeded stub" files (`systemPatterns.md`, `activeContext.md`, `progress.md`) may contain `(fill in ...)` notes for future sessions, but must have the project name and date inserted.
- Always ask questions one at a time — do not batch them.
