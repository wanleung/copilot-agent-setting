# Memory Bank for Copilot CLI — Design Spec

**Date:** 2026-04-03  
**Status:** Approved  
**Scope:** `copilot-agent-setting` template + both orchestrators (`copilot-software-house`, `ai-software-house`)

---

## Problem

GitHub Copilot CLI has no persistent memory across sessions. Each session starts from scratch, requiring the user to re-explain the project, its architecture, current state, and outstanding work. Cline solves this with a "Memory Bank" — a set of structured Markdown files read at session start.

This spec describes how to implement an equivalent for Copilot CLI.

---

## Approach

**Approach A — Markdown files committed to target repo.**

Six structured Markdown files live in `memory-bank/` inside each target project repo. `.github/copilot-instructions.md` directs Copilot to read them at session start. Both orchestrators auto-update these files at the end of each pipeline run.

`copilot-agent-setting/` holds a template and a deploy script so any project can adopt the pattern.

---

## File Structure

### Template (in `copilot-agent-setting/memory-bank/`)

```text
memory-bank/
├── projectbrief.md      # Goals, scope, core requirements — changes rarely
├── productContext.md    # Why it exists, user problems, UX goals — changes rarely
├── systemPatterns.md    # Architecture, module relationships, patterns used — updated when design changes
├── techContext.md       # Tech stack, dependencies, environment constraints — updated when stack changes
├── activeContext.md     # Current focus, recent changes, immediate next steps — updated every run
└── progress.md          # Done / in-progress / blockers / known issues — updated every run
```

Hierarchy: `projectbrief → productContext → systemPatterns/techContext → activeContext → progress`

### Deployed to a target project

```text
<project-root>/
├── .github/
│   └── copilot-instructions.md   ← auto-loaded by Copilot CLI and VS Code
└── memory-bank/
    ├── projectbrief.md
    ├── productContext.md
    ├── systemPatterns.md
    ├── techContext.md
    ├── activeContext.md
    └── progress.md
```

---

## `.github/copilot-instructions.md`

Contains two sections:

1. **Memory bank directive** — read all `memory-bank/*.md` in hierarchy order before starting any task; update `activeContext.md` and `progress.md` after completing work.

2. **Agent roles index** — brief description of which agent system-prompt file to use at each pipeline stage, linking to `copilot-agent-setting/agents/`.

Auto-loaded by:
- GitHub Copilot extension in VS Code
- `copilot --yolo` CLI in any directory containing it
- `copilot -p` CLI when run inside the repo

---

## Automatic Updates — `MemoryBankUpdaterAgent`

### New agent (both `copilot-software-house` and `ai-software-house`)

**File:** `agents/memory_bank_updater.py`  
**Role file:** `roles/memory_bank_updater.md`

**Input:**
- `current_bank: dict[str, str]` — current content of each memory-bank file (filename → content)
- `run_summary: str` — the compact summary produced by `SummaryAgent` at end of run

**Output:** `updated_bank: dict[str, str]` — proposed new content for files that need updating

The agent is instructed to:
- Always update `activeContext.md` (current focus → just-completed work; next steps → queued issues)
- Always update `progress.md` (move in-progress items to done; add new items)
- Update `systemPatterns.md` if the run produced a new system design
- Update `techContext.md` if new dependencies or constraints were introduced
- Leave `projectbrief.md` and `productContext.md` unchanged unless the requirements explicitly changed

### Integration into orchestrators

In `_finish()` (after `SummaryAgent` runs):

```python
# Read current memory bank from target repo
current_bank = self._read_memory_bank()   # fetches via GitHub API or local clone
# Generate updates
updater = MemoryBankUpdaterAgent(...)
updated_bank = updater.update(current_bank, run_summary)
# Commit updated files to feature branch
self._write_memory_bank(updated_bank, branch)
```

`_read_memory_bank()` — reads from `workspace/<repo>/repo/memory-bank/` (the local clone created by `ensure_repo_clone()`). Falls back to empty templates if files don't exist yet (first run).

`_write_memory_bank()` — writes files to the local clone, then commits via `self.github.commit_file()` to the feature branch.

### `copilot-software-house` specifics

- Subprocess agent: `MemoryBankUpdaterAgent` extends `BaseAgent`, uses `cwd=self._repo_cwd`
- Prompt includes the current file contents + run summary, asks for the full new content of each changed file using `### FILE: memory-bank/<name>.md` format

### `ai-software-house` specifics

- API agent: `MemoryBankUpdaterAgent` extends `BaseAgent`, uses GitHub Models / Anthropic API
- Response parsed the same way as engineer output (file markers)

---

## `copilot-agent-setting` additions

### `memory-bank/` template directory

Six template files with placeholder content and clear section headings. Copy into any project with:

```bash
./deploy-memory-bank.sh owner/project-name
```

### `deploy-memory-bank.sh`

```bash
#!/usr/bin/env bash
# Usage: ./deploy-memory-bank.sh [target-directory]
# Copies memory-bank/ and .github/copilot-instructions.md into target.
TARGET=${1:-.}
mkdir -p "$TARGET/memory-bank" "$TARGET/.github"
cp memory-bank/*.md "$TARGET/memory-bank/"
cp .github/copilot-instructions.md "$TARGET/.github/"
echo "Memory bank deployed to $TARGET"
```

### `update-memory-bank.sh` (manual sessions)

```bash
#!/usr/bin/env bash
# Usage: ./update-memory-bank.sh "summary of what you just did"
# Runs copilot to propose memory bank updates, writes them to memory-bank/
SUMMARY=${1:-"session update"}
copilot --yolo -p "Read all files in memory-bank/. Based on this summary: '$SUMMARY', update activeContext.md and progress.md. Write the full updated content of each file."
```

---

## Error Handling

- If `memory-bank/` does not exist in the target repo: agent uses empty templates; orchestrator creates the files on first commit.
- If GitHub commit fails: log a warning and continue — memory bank is supplementary, not blocking.
- If agent produces malformed output: skip writing and log; existing files are preserved.

---

## Out of Scope

- Automatic semantic versioning of memory bank entries
- Vector search over memory bank content
- Memory bank sync across multiple branches

---

## Implementation Plan (next step)

Invoke `writing-plans` skill to produce the full task breakdown.
