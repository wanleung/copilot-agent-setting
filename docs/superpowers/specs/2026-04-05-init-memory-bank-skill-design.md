# `init-memory-bank` Skill — Design Spec

**Date:** 2026-04-05
**Status:** Approved
**Scope:** `copilot-agent-setting` — new skill + install script

---

## Problem

When starting a new project, the Memory Bank template files (`memory-bank/*.md`) contain only
placeholder text. The user must manually edit 3–6 files before Copilot CLI has any useful context.
This friction means the memory bank often stays as empty templates and never gets used.

---

## Solution

A new superpowers skill `init-memory-bank` that guides the user through setup in a single
interactive session. It asks ~5 focused questions, infers what it can from existing files,
and writes fully populated versions of `projectbrief.md`, `productContext.md`, and
`techContext.md`. The other three files are seeded with project context but left as
structured stubs for the user to complete as the project evolves.

---

## Skill Behaviour

### Trigger

Invoked via the `skill` tool: `skill: "init-memory-bank"`

Works from inside any project directory that:
- Has `memory-bank/` (deployed via `deploy-memory-bank.sh`), OR
- Does not yet have `memory-bank/` (skill deploys it from `copilot-agent-setting`)

### Step 1 — Scan existing files

Before asking any questions, scan the current directory for:

- `package.json` → infer Node.js/TypeScript stack and project name
- `pyproject.toml` / `requirements.txt` → infer Python stack
- `Cargo.toml` → infer Rust stack
- `go.mod` → infer Go stack
- `pubspec.yaml` → infer Flutter/Dart stack
- `README.md` → extract project name and any description
- `docker-compose.yml` / `Dockerfile` → note containerisation

Report what was detected before asking questions:
> "I found `package.json` (Node.js) and `docker-compose.yml`. I'll use these to
> pre-fill the tech stack. Let me ask a few questions about the rest."

If `memory-bank/` does not exist, run `deploy-memory-bank.sh .` first (or create
the directory and copy templates from `copilot-agent-setting/memory-bank/`).

### Step 2 — Ask 5 questions (one at a time)

1. **Project name and goal** — "What is this project, and what does it do in one sentence?"
2. **User problem** — "What problem does this solve for users? Who are the target users?"
3. **Core requirements** — "What are the 3–5 most important things it must do?"
4. **Tech stack confirmation** — Show detected stack, ask to confirm or correct.
   If nothing detected: "What's the tech stack? (language, framework, database, infra)"
5. **Git hook** — "Should I install the semi-auto git hook so the memory bank updates
   after every commit? (Recommended)"

### Step 3 — Write files

#### Fully populated (all placeholders replaced):

- **`memory-bank/projectbrief.md`** — project name, goal, core requirements from Q1+Q3
- **`memory-bank/productContext.md`** — user problem and target users from Q2
- **`memory-bank/techContext.md`** — tech stack from Q4, dev setup commands inferred
  from detected files (e.g., `npm install`, `pip install -r requirements.txt`)

#### Seeded stubs (project name/context inserted, sections marked for later):

- **`memory-bank/systemPatterns.md`** — architecture overview section says
  "Fill in once initial architecture is decided." Module relationships left as template.
- **`memory-bank/activeContext.md`** — Current Focus set to "Initial project setup",
  Next Steps set to "Fill in systemPatterns.md once architecture is designed."
- **`memory-bank/progress.md`** — In Progress: "Initial project setup",
  Upcoming: list of core requirements from Q3.

#### Optional:

If Q5 answered yes: run `install-memory-bank-hook.sh .`

### Step 4 — Report

Print a summary:
```
✅ Memory Bank initialised

Fully populated:
  memory-bank/projectbrief.md
  memory-bank/productContext.md
  memory-bank/techContext.md

Seeded (fill in as project evolves):
  memory-bank/systemPatterns.md  ← fill after architecture is designed
  memory-bank/activeContext.md
  memory-bank/progress.md

[✅ Git hook installed — bank will auto-update after every commit]

Copilot CLI will now read these files at the start of every session.
```

---

## File Storage

### Skill source

```text
copilot-agent-setting/
└── skills/
    └── init-memory-bank/
        └── SKILL.md
```

### Install destination

```text
~/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills/init-memory-bank/SKILL.md
```

### `install-skill.sh` (new file at repo root)

Copies all skill directories from `copilot-agent-setting/skills/` into the superpowers
plugin directory. Idempotent — safe to re-run after skill updates.

```bash
#!/usr/bin/env bash
# Usage: ./install-skill.sh
# Installs all skills from skills/ into the superpowers plugin directory.
DEST="$HOME/.copilot/installed-plugins/superpowers-marketplace/superpowers/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DEST"
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    name=$(basename "$skill_dir")
    cp -r "$skill_dir" "$DEST/$name"
    echo "Installed: $name"
done
echo "Done. Restart Copilot CLI to pick up new skills."
```

---

## Skill File Structure

```
skills/init-memory-bank/SKILL.md
```

The `SKILL.md` follows the superpowers skill format:
- YAML frontmatter: `name`, `description`
- Markdown body: step-by-step instructions the AI agent follows

The skill is **not** a Python script — it is instructions for the Copilot CLI AI agent.
The agent reads the instructions and executes them using its built-in tools (file read/write,
bash commands, `ask_user`).

---

## Error Handling

- If `deploy-memory-bank.sh` is not found (not run from `copilot-agent-setting` clone):
  skill creates `memory-bank/` directly using inline template content.
- If git hook install fails (not a git repo): skip silently, note in report.
- If a question is skipped/unclear: use sensible defaults and note as "fill in later".

---

## Out of Scope

- Populating `systemPatterns.md` fully (requires architectural decisions not yet made)
- Updating an already-populated memory bank (that's `update-memory-bank.sh`)
- Multi-repo setup

---

## Implementation Plan (next step)

Invoke `writing-plans` skill to produce the task breakdown.
