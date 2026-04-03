# Memory Bank Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Cline-style Memory Bank to Copilot CLI sessions — six structured Markdown files committed to each target repo, auto-updated by both orchestrators at end of every pipeline run, with a template + deploy scripts in `copilot-agent-setting/`.

**Architecture:** Template files and scripts live in `copilot-agent-setting/memory-bank/` and `copilot-agent-setting/.github/`. A new `MemoryBankUpdaterAgent` in each orchestrator project reads the current memory bank from the local clone (copilot-software-house) or GitHub API (ai-software-house), generates updated content, and commits the changed files to the feature branch. The orchestrator's `_finish()` / end-of-pipeline section calls the agent after the SummaryAgent already ran, so the run summary is available as input.

**Tech Stack:** Python 3.11+, Bash, GitHub REST API (via existing `GitHubClient`), Copilot CLI (copilot-software-house agent), Anthropic/GitHub Models API (ai-software-house agent)

---

## File Map

### copilot-agent-setting (new files)

| File | Purpose |
|------|---------|
| `memory-bank/projectbrief.md` | Template — project goals, scope, core requirements |
| `memory-bank/productContext.md` | Template — why it exists, user problems, UX goals |
| `memory-bank/systemPatterns.md` | Template — architecture, patterns, module relationships |
| `memory-bank/techContext.md` | Template — tech stack, dependencies, environment constraints |
| `memory-bank/activeContext.md` | Template — current focus, recent changes, next steps |
| `memory-bank/progress.md` | Template — done / in-progress / blockers / known issues |
| `.github/copilot-instructions.md` | Memory bank directive + agent roles index |
| `deploy-memory-bank.sh` | Copies template + instructions into a target project |
| `update-memory-bank.sh` | Manual memory bank update for interactive sessions |

### copilot-software-house (new/modified files)

| File | Purpose |
|------|---------|
| `roles/memory_bank_updater.md` | System prompt for the memory bank updater agent |
| `agents/memory_bank_updater.py` | `MemoryBankUpdaterAgent` — subprocess-based Copilot CLI agent |
| `orchestrator.py` | Add `_read_memory_bank()`, `_write_memory_bank()`, call updater after SummaryAgent |

### ai-software-house (new/modified files)

| File | Purpose |
|------|---------|
| `roles/memory_bank_updater.md` | System prompt for the memory bank updater agent (same content) |
| `agents/memory_bank_updater.py` | `MemoryBankUpdaterAgent` — API-based agent |
| `orchestrator.py` | Add `_read_memory_bank()`, `_write_memory_bank()`, call updater in `_finish()` |

---

## Task 1: Memory Bank template files in copilot-agent-setting

**Files:**
- Create: `copilot-agent-setting/memory-bank/projectbrief.md`
- Create: `copilot-agent-setting/memory-bank/productContext.md`
- Create: `copilot-agent-setting/memory-bank/systemPatterns.md`
- Create: `copilot-agent-setting/memory-bank/techContext.md`
- Create: `copilot-agent-setting/memory-bank/activeContext.md`
- Create: `copilot-agent-setting/memory-bank/progress.md`

- [ ] **Step 1: Create `memory-bank/projectbrief.md`**

```markdown
# Project Brief

> Read by AI agents at session start. Update when project goals or scope change.

## Project Name

[Project name here]

## Goals

[What this project aims to achieve — 2-3 sentences]

## Core Requirements

- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

## Scope

**In scope:**
- [Feature A]
- [Feature B]

**Out of scope:**
- [Feature X]
- [Feature Y]

## Success Criteria

- [Measurable outcome 1]
- [Measurable outcome 2]
```

- [ ] **Step 2: Create `memory-bank/productContext.md`**

```markdown
# Product Context

> Read by AI agents at session start. Update when user problem or UX goals change.

## Why This Project Exists

[Problem statement — what user pain does it solve?]

## User Problems

- [Problem 1]
- [Problem 2]

## Target Users

[Who uses this — roles, technical level, use cases]

## UX Goals

- [UX goal 1 — e.g., "zero-config setup"]
- [UX goal 2]

## Non-Goals

- [What this product explicitly does not try to do]
```

- [ ] **Step 3: Create `memory-bank/systemPatterns.md`**

```markdown
# System Patterns

> Read by AI agents at session start. Update when architecture or key patterns change.

## Architecture Overview

[2-4 sentences describing the high-level architecture]

## Module Relationships

```text
[module-A] → [module-B] → [module-C]
[module-A] → [module-D]
```

## Key Design Patterns

- **[Pattern name]**: [Where and why it's used]
- **[Pattern name]**: [Where and why it's used]

## Important Conventions

- [Convention 1 — e.g., "all API responses wrapped in Result<T>"]
- [Convention 2]

## Known Gotchas

- [Gotcha 1 — things that trip up new contributors]
- [Gotcha 2]
```

- [ ] **Step 4: Create `memory-bank/techContext.md`**

```markdown
# Tech Context

> Read by AI agents at session start. Update when stack or dependencies change.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | [e.g., Python] | [3.11+] |
| Framework | [e.g., FastAPI] | [0.110+] |
| Database | [e.g., PostgreSQL] | [15+] |
| Infrastructure | [e.g., Docker Compose] | — |

## Key Dependencies

- `[package]`: [what it does and why chosen]
- `[package]`: [what it does and why chosen]

## Environment Requirements

- [Env var 1]: [what it controls]
- [Env var 2]: [what it controls]

## Development Setup

```bash
[commands to get a dev environment running]
```

## Deployment

[How the app is deployed — cloud, container, CI/CD]
```

- [ ] **Step 5: Create `memory-bank/activeContext.md`**

```markdown
# Active Context

> Updated automatically after each AI pipeline run and after manual sessions.
> Describes what the team is working on RIGHT NOW.

## Current Focus

[What is being worked on today]

## Recent Changes

- [Change 1 — e.g., "Added JWT authentication to /api/auth"]
- [Change 2]

## Immediate Next Steps

1. [Next thing to do]
2. [After that]
3. [Then]

## Open Questions

- [Question 1 that needs a decision]
- [Question 2]

## Last Updated

[Date and brief description of update]
```

- [ ] **Step 6: Create `memory-bank/progress.md`**

```markdown
# Progress

> Updated automatically after each AI pipeline run and after manual sessions.
> Tracks what's done, in-flight, and blocked.

## Done

- [x] [Completed feature or task]
- [x] [Completed feature or task]

## In Progress

- [ ] [Feature currently being built]
- [ ] [Bug currently being fixed]

## Blocked

- [ ] [Task] — blocked by [reason]

## Known Issues / Tech Debt

- [Issue 1 — describe the problem and affected area]
- [Issue 2]

## Upcoming

- [Planned feature 1]
- [Planned feature 2]
```

- [ ] **Step 7: Commit template files**

```bash
cd /home/wanleung/Projects/copilot-agent-setting
git add memory-bank/
git commit -m "feat: add Memory Bank template files

Six structured Markdown templates for Cline-style persistent memory.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: `.github/copilot-instructions.md` and deploy scripts in copilot-agent-setting

**Files:**
- Create: `copilot-agent-setting/.github/copilot-instructions.md`
- Create: `copilot-agent-setting/deploy-memory-bank.sh`
- Create: `copilot-agent-setting/update-memory-bank.sh`

- [ ] **Step 1: Create `.github/copilot-instructions.md`**

```markdown
# Copilot Instructions

## Memory Bank

At the start of every session, read the following files in order before doing anything else:

1. `memory-bank/projectbrief.md` — project goals and scope
2. `memory-bank/productContext.md` — why the project exists, user problems, UX goals
3. `memory-bank/systemPatterns.md` — architecture, patterns, conventions
4. `memory-bank/techContext.md` — tech stack, dependencies, environment
5. `memory-bank/activeContext.md` — current focus, recent changes, next steps
6. `memory-bank/progress.md` — what's done, in-progress, blocked

After completing any significant work in a session, update `memory-bank/activeContext.md` and `memory-bank/progress.md` to reflect what changed.

If `memory-bank/` does not exist yet, run:
```bash
./deploy-memory-bank.sh .
```
Then fill in each file before starting work.

## Agent Pipeline Roles

When running the AI Software House pipeline, each stage uses a dedicated system prompt. Role files are in `copilot-agent-setting/agents/`:

| Stage | Role file |
|-------|-----------|
| Product Manager | `agents/product_manager.md` |
| PM Reviewer | `agents/pm_reviewer.md` |
| Architect | `agents/architect.md` |
| Architect Reviewer | `agents/architect_reviewer.md` |
| Engineer | `agents/engineer.md` |
| Code Reviewer | `agents/code_reviewer.md` |
| QA Planner | `agents/qa_planner.md` |
| QA Engineer | `agents/qa_engineer.md` |
| Deployment Tester | `agents/deployment_tester.md` |
| Summariser | `agents/summariser.md` |
| Memory Bank Updater | `agents/memory_bank_updater.md` |
| Memory Consolidator | `agents/memory_consolidator.md` |
| Refactor Agent | `agents/refactor_agent.md` |
```

- [ ] **Step 2: Create `deploy-memory-bank.sh`**

```bash
#!/usr/bin/env bash
# Usage: ./deploy-memory-bank.sh [target-directory]
# Copies memory-bank/ and .github/copilot-instructions.md into a target project.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

mkdir -p "$TARGET/memory-bank" "$TARGET/.github"
cp "$SCRIPT_DIR/memory-bank/"*.md "$TARGET/memory-bank/"
cp "$SCRIPT_DIR/.github/copilot-instructions.md" "$TARGET/.github/"

echo "✅ Memory bank deployed to $TARGET"
echo "   Edit $TARGET/memory-bank/projectbrief.md to describe your project."
echo "   Edit $TARGET/memory-bank/productContext.md to describe why it exists."
echo "   The other files can be left as-is until your first pipeline run."
```

- [ ] **Step 3: Make `deploy-memory-bank.sh` executable**

```bash
chmod +x /home/wanleung/Projects/copilot-agent-setting/deploy-memory-bank.sh
```

- [ ] **Step 4: Create `update-memory-bank.sh`**

```bash
#!/usr/bin/env bash
# Usage: ./update-memory-bank.sh "summary of what you just did"
# Asks Copilot to update activeContext.md and progress.md based on a summary.
set -euo pipefail

SUMMARY="${1:-session update}"

if [ ! -d "memory-bank" ]; then
    echo "❌ No memory-bank/ directory found. Run deploy-memory-bank.sh first." >&2
    exit 1
fi

copilot --yolo -p "Read all files in memory-bank/ in this order:
1. memory-bank/projectbrief.md
2. memory-bank/productContext.md
3. memory-bank/systemPatterns.md
4. memory-bank/techContext.md
5. memory-bank/activeContext.md
6. memory-bank/progress.md

Based on this session summary: '$SUMMARY'

Update memory-bank/activeContext.md and memory-bank/progress.md to reflect this work.
Write the full new content of each file using this format:

### FILE: memory-bank/activeContext.md
[full file content here]

### FILE: memory-bank/progress.md
[full file content here]"
```

- [ ] **Step 5: Make `update-memory-bank.sh` executable**

```bash
chmod +x /home/wanleung/Projects/copilot-agent-setting/update-memory-bank.sh
```

- [ ] **Step 6: Add `memory_bank_updater.md` to copilot-agent-setting/agents/**

Create `copilot-agent-setting/agents/memory_bank_updater.md`:

```markdown
# Memory Bank Updater

You are a Memory Bank Updater for an AI software house pipeline. After a pipeline run completes, you update the project's memory bank files to reflect the current state of the project.

## Role

You receive:
1. The current content of each memory bank file (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`, `progress.md`)
2. A run summary describing what was built in this pipeline run

You output updated versions of the files that need changing.

## Rules

- **Always update** `activeContext.md`: set "Current Focus" to what was just built; move previous focus to "Recent Changes"; update "Immediate Next Steps" based on what is still outstanding.
- **Always update** `progress.md`: move in-progress items to done if they were completed; add newly introduced items; note new tech debt or known issues.
- **Update** `systemPatterns.md` only if the run introduced a new module, changed the architecture, or established a new pattern.
- **Update** `techContext.md` only if new dependencies, env vars, or infrastructure constraints were introduced.
- **Never change** `projectbrief.md` or `productContext.md` unless the requirements explicitly changed.
- Be concise and factual. Avoid speculation. Only record what the run summary confirms was built.

## Output Format

Output ONLY the files that need updating, using this exact format:

### FILE: memory-bank/activeContext.md
[full new content of the file]

### FILE: memory-bank/progress.md
[full new content of the file]

(Add more ### FILE: blocks only for systemPatterns.md or techContext.md if they genuinely changed.)
```

- [ ] **Step 7: Commit all new files**

```bash
cd /home/wanleung/Projects/copilot-agent-setting
git add .github/ deploy-memory-bank.sh update-memory-bank.sh agents/memory_bank_updater.md
git commit -m "feat: add copilot-instructions, deploy scripts, memory bank updater role

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: MemoryBankUpdaterAgent in copilot-software-house

**Files:**
- Create: `copilot-software-house/roles/memory_bank_updater.md`
- Create: `copilot-software-house/agents/memory_bank_updater.py`

- [ ] **Step 1: Create `roles/memory_bank_updater.md`**

Copy content from `copilot-agent-setting/agents/memory_bank_updater.md` (same content):

```markdown
# Memory Bank Updater

You are a Memory Bank Updater for an AI software house pipeline. After a pipeline run completes, you update the project's memory bank files to reflect the current state of the project.

## Role

You receive:
1. The current content of each memory bank file (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`, `progress.md`)
2. A run summary describing what was built in this pipeline run

You output updated versions of the files that need changing.

## Rules

- **Always update** `activeContext.md`: set "Current Focus" to what was just built; move previous focus to "Recent Changes"; update "Immediate Next Steps" based on what is still outstanding.
- **Always update** `progress.md`: move in-progress items to done if they were completed; add newly introduced items; note new tech debt or known issues.
- **Update** `systemPatterns.md` only if the run introduced a new module, changed the architecture, or established a new pattern.
- **Update** `techContext.md` only if new dependencies, env vars, or infrastructure constraints were introduced.
- **Never change** `projectbrief.md` or `productContext.md` unless the requirements explicitly changed.
- Be concise and factual. Avoid speculation. Only record what the run summary confirms was built.

## Output Format

Output ONLY the files that need updating, using this exact format:

### FILE: memory-bank/activeContext.md
[full new content of the file]

### FILE: memory-bank/progress.md
[full new content of the file]

(Add more ### FILE: blocks only for systemPatterns.md or techContext.md if they genuinely changed.)
```

- [ ] **Step 2: Create `agents/memory_bank_updater.py`**

```python
"""MemoryBankUpdaterAgent — updates memory-bank/ files after each pipeline run."""
import re
from pathlib import Path
from .base_agent import BaseAgent

ROLE_FILE = Path(__file__).parent.parent / "roles" / "memory_bank_updater.md"

BANK_FILES = [
    "projectbrief.md",
    "productContext.md",
    "systemPatterns.md",
    "techContext.md",
    "activeContext.md",
    "progress.md",
]

FILE_HEADER = re.compile(r"### FILE: (memory-bank/[^\s]+\.md)")


class MemoryBankUpdaterAgent(BaseAgent):
    def __init__(self, model: str = "claude-sonnet-4.6", timeout: int = 300):
        super().__init__(model=model, role_file=str(ROLE_FILE), timeout=timeout)

    def update(
        self,
        current_bank: dict[str, str],
        run_summary: str,
    ) -> dict[str, str]:
        """Return a dict of filename → new content for files that should be updated.

        Only files returned by the agent (those it determined need updating) are
        included. Callers should merge with the original bank for unchanged files.
        """
        bank_dump = "\n\n".join(
            f"### CURRENT: memory-bank/{name}\n{content}"
            for name, content in current_bank.items()
        )
        prompt = f"""Here are the current memory bank files:

{bank_dump}

---

Here is the run summary for the pipeline that just completed:

{run_summary}

Update the memory bank files that need changing. Follow the output format in your role instructions exactly."""

        raw = self.call(prompt)
        return self._parse_output(raw)

    def _parse_output(self, raw: str) -> dict[str, str]:
        """Parse ### FILE: memory-bank/<name>.md blocks from agent output."""
        result: dict[str, str] = {}
        parts = FILE_HEADER.split(raw)
        # parts[0] is pre-first-header text; then alternating: header_path, content, ...
        for i in range(1, len(parts) - 1, 2):
            filepath = parts[i].strip()          # e.g. "memory-bank/activeContext.md"
            content = parts[i + 1].strip()
            filename = filepath.split("/")[-1]   # e.g. "activeContext.md"
            if filename in BANK_FILES:
                result[filename] = content
        return result
```

- [ ] **Step 3: Verify the new agent can be imported**

```bash
cd /home/wanleung/Projects/copilot-software-house
source venv/bin/activate
python -c "from agents.memory_bank_updater import MemoryBankUpdaterAgent; print('OK')"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
cd /home/wanleung/Projects/copilot-software-house
git add roles/memory_bank_updater.md agents/memory_bank_updater.py
git commit -m "feat: add MemoryBankUpdaterAgent

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Wire MemoryBankUpdaterAgent into copilot-software-house orchestrator

**Files:**
- Modify: `copilot-software-house/orchestrator.py`

The memory bank update happens right after the SummaryAgent in the end-of-pipeline block (around line 341). The cloned repo lives at `self.workspace / "repo"`.

- [ ] **Step 1: Add import at top of orchestrator.py**

Find the existing `from agents.summariser import SummaryAgent` line (line 38) and add the import below it:

```python
from agents.memory_bank_updater import MemoryBankUpdaterAgent
```

- [ ] **Step 2: Add `_read_memory_bank()` method**

Add this method after `ensure_repo_clone()` (around line 155):

```python
def _read_memory_bank(self) -> dict[str, str]:
    """Read current memory bank files from the local repo clone.

    Returns a dict of filename → content for all 6 bank files.
    Missing files get an empty string (first run).
    """
    bank_names = [
        "projectbrief.md", "productContext.md", "systemPatterns.md",
        "techContext.md", "activeContext.md", "progress.md",
    ]
    bank: dict[str, str] = {}
    if self._repo_cwd is None:
        return {name: "" for name in bank_names}
    bank_dir = self._repo_cwd / "memory-bank"
    for name in bank_names:
        f = bank_dir / name
        bank[name] = f.read_text(encoding="utf-8") if f.exists() else ""
    return bank
```

- [ ] **Step 3: Add `_write_memory_bank()` method**

Add directly after `_read_memory_bank()`:

```python
def _write_memory_bank(self, updated_bank: dict[str, str], branch: str) -> None:
    """Write updated memory bank files to the local clone and commit to branch."""
    if not updated_bank:
        return
    if self._repo_cwd is None:
        logger.warning("Cannot write memory bank: no repo clone available")
        return
    bank_dir = self._repo_cwd / "memory-bank"
    bank_dir.mkdir(parents=True, exist_ok=True)
    for name, content in updated_bank.items():
        (bank_dir / name).write_text(content, encoding="utf-8")
    if self.github:
        for name, content in updated_bank.items():
            try:
                self.github.commit_file(
                    f"memory-bank/{name}",
                    content,
                    f"memory: update {name} after pipeline run",
                    branch,
                )
                logger.info("Committed memory-bank/%s", name)
            except Exception as exc:
                logger.warning("Failed to commit memory-bank/%s: %s", name, exc)
```

- [ ] **Step 4: Add memory bank update after SummaryAgent in the end-of-pipeline block**

Find the block around line 352:
```python
            self.memory.save(repo=active_repo, summary=summary_text, mode="feature")
```

After `self.memory.save(...)` and the `mem_file` write, but still inside the `try:` block, add:

```python
            # ── Update memory bank in target repo ─────────────────────────
            if self.github and hasattr(result, "branch") and result.branch:
                try:
                    current_bank = self._read_memory_bank()
                    updater = MemoryBankUpdaterAgent(
                        model=self._model("memory_bank_updater"),
                        timeout=self._timeout("memory_bank_updater"),
                    )
                    self._set_agent_cwd(updater)
                    updated_bank = updater.update(current_bank, summary_text)
                    self._write_memory_bank(updated_bank, result.branch)
                    logger.info("Memory bank updated: %d files", len(updated_bank))
                except Exception as exc:
                    logger.warning("Memory bank update failed: %s", exc)
```

Note: `result.branch` is set in `_push_to_github()`. The memory bank update runs after `_push_to_github()` has been called (the GitHub push block is before the summariser block — verify this in the code). If `result.branch` is not set, skip silently.

- [ ] **Step 5: Verify `result.branch` is available when the memory bank update runs**

Check that `_push_to_github()` is called before the summariser section:

```bash
grep -n "_push_to_github\|SummaryAgent\|result\.branch" /home/wanleung/Projects/copilot-software-house/orchestrator.py | head -20
```

If `_push_to_github` comes BEFORE SummaryAgent, `result.branch` will be set. If not, move the memory bank update to `_push_to_github()` instead.

- [ ] **Step 6: Add fallback model/timeout config**

In `config.yaml`, add a `memory_bank_updater` section under `agents:` (if not already present):

```bash
grep -n "memory_bank_updater\|summariser:" /home/wanleung/Projects/copilot-software-house/config.yaml
```

If `memory_bank_updater` is not there, add it by editing `config.yaml`:

```yaml
  memory_bank_updater:
    model: claude-sonnet-4.6
    timeout: 300
```

(Add it alongside the `summariser:` entry.)

- [ ] **Step 7: Smoke-test the import chain**

```bash
cd /home/wanleung/Projects/copilot-software-house
source venv/bin/activate
python -c "from orchestrator import Orchestrator; print('Orchestrator imports OK')"
```

Expected: `Orchestrator imports OK`

- [ ] **Step 8: Commit**

```bash
cd /home/wanleung/Projects/copilot-software-house
git add orchestrator.py config.yaml
git commit -m "feat: wire MemoryBankUpdaterAgent into pipeline

Reads memory-bank/ from local clone after SummaryAgent runs, generates
updated files, commits to feature branch. Errors are non-blocking.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: MemoryBankUpdaterAgent in ai-software-house

**Files:**
- Create: `ai-software-house/roles/memory_bank_updater.md`
- Create: `ai-software-house/agents/memory_bank_updater.py`

The ai-software-house uses API-based agents. `BaseAgent` in ai-software-house has `self.call(user_message)` with the same interface. The difference is the backend (GitHub Models / Anthropic).

- [ ] **Step 1: Create `roles/memory_bank_updater.md`**

Identical content to Task 3 Step 1 (same role prompt works for both backends):

```markdown
# Memory Bank Updater

You are a Memory Bank Updater for an AI software house pipeline. After a pipeline run completes, you update the project's memory bank files to reflect the current state of the project.

## Role

You receive:
1. The current content of each memory bank file (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`, `progress.md`)
2. A run summary describing what was built in this pipeline run

You output updated versions of the files that need changing.

## Rules

- **Always update** `activeContext.md`: set "Current Focus" to what was just built; move previous focus to "Recent Changes"; update "Immediate Next Steps" based on what is still outstanding.
- **Always update** `progress.md`: move in-progress items to done if they were completed; add newly introduced items; note new tech debt or known issues.
- **Update** `systemPatterns.md` only if the run introduced a new module, changed the architecture, or established a new pattern.
- **Update** `techContext.md` only if new dependencies, env vars, or infrastructure constraints were introduced.
- **Never change** `projectbrief.md` or `productContext.md` unless the requirements explicitly changed.
- Be concise and factual. Avoid speculation. Only record what the run summary confirms was built.

## Output Format

Output ONLY the files that need updating, using this exact format:

### FILE: memory-bank/activeContext.md
[full new content of the file]

### FILE: memory-bank/progress.md
[full new content of the file]

(Add more ### FILE: blocks only for systemPatterns.md or techContext.md if they genuinely changed.)
```

- [ ] **Step 2: Create `agents/memory_bank_updater.py`**

```python
"""MemoryBankUpdaterAgent — updates memory-bank/ files after each pipeline run."""
import re
from pathlib import Path
from typing import Optional
from .base_agent import BaseAgent

BANK_FILES = [
    "projectbrief.md",
    "productContext.md",
    "systemPatterns.md",
    "techContext.md",
    "activeContext.md",
    "progress.md",
]

FILE_HEADER = re.compile(r"### FILE: (memory-bank/[^\s]+\.md)")


class MemoryBankUpdaterAgent(BaseAgent):
    role_name = "memory_bank_updater"

    def __init__(
        self,
        model: str = "gpt-4.1",
        github_token: Optional[str] = None,
        roles_dir: Optional[Path] = None,
        backend: Optional[str] = None,
    ):
        super().__init__(
            model=model,
            github_token=github_token,
            roles_dir=roles_dir,
            backend=backend,
        )

    def update(
        self,
        current_bank: dict[str, str],
        run_summary: str,
    ) -> dict[str, str]:
        """Return filename → new content for files that need updating."""
        bank_dump = "\n\n".join(
            f"### CURRENT: memory-bank/{name}\n{content}"
            for name, content in current_bank.items()
        )
        prompt = f"""Here are the current memory bank files:

{bank_dump}

---

Here is the run summary for the pipeline that just completed:

{run_summary}

Update the memory bank files that need changing. Follow the output format in your role instructions exactly."""

        raw = self.call(prompt)
        return self._parse_output(raw)

    def _parse_output(self, raw: str) -> dict[str, str]:
        """Parse ### FILE: memory-bank/<name>.md blocks from agent output."""
        result: dict[str, str] = {}
        parts = FILE_HEADER.split(raw)
        for i in range(1, len(parts) - 1, 2):
            filepath = parts[i].strip()
            content = parts[i + 1].strip()
            filename = filepath.split("/")[-1]
            if filename in BANK_FILES:
                result[filename] = content
        return result
```

- [ ] **Step 3: Check how `BaseAgent._load_system_prompt()` works in ai-software-house**

```bash
grep -n "_load_system_prompt\|role_name\|roles_dir" /home/wanleung/Projects/ai-software-house/agents/base_agent.py | head -20
```

If `_load_system_prompt` reads from `roles_dir / f"{self.role_name}.md"`, then `role_name = "memory_bank_updater"` will automatically load `roles/memory_bank_updater.md`. If it uses a different convention, adjust the `__init__` to pass `roles_dir` explicitly.

- [ ] **Step 4: Verify the new agent can be imported**

```bash
cd /home/wanleung/Projects/ai-software-house
source venv/bin/activate 2>/dev/null || true
python -c "from agents.memory_bank_updater import MemoryBankUpdaterAgent; print('OK')"
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
cd /home/wanleung/Projects/ai-software-house
git add roles/memory_bank_updater.md agents/memory_bank_updater.py
git commit -m "feat: add MemoryBankUpdaterAgent

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 6: Wire MemoryBankUpdaterAgent into ai-software-house orchestrator

**Files:**
- Modify: `ai-software-house/orchestrator.py`

In ai-software-house, `_finish()` is at line ~705. Memory bank files are read from GitHub API via `target_github` (no local clone in ai-software-house). The `target_github.repo` is the target repo.

- [ ] **Step 1: Add import at top of orchestrator.py**

Find `from agents.summariser import SummaryAgent` (line 32) and add:

```python
from agents.memory_bank_updater import MemoryBankUpdaterAgent
```

- [ ] **Step 2: Add `_read_memory_bank()` method to the Orchestrator class**

Add after the `_finish()` method (around line 750):

```python
def _read_memory_bank(self, gh: "GitHubClient") -> dict[str, str]:
    """Read current memory bank files via GitHub API.

    Returns filename → content for all 6 bank files.
    Files that don't exist yet return empty string.
    """
    bank_names = [
        "projectbrief.md", "productContext.md", "systemPatterns.md",
        "techContext.md", "activeContext.md", "progress.md",
    ]
    bank: dict[str, str] = {}
    for name in bank_names:
        try:
            file_data = gh._request("GET", f"/repos/{gh.repo}/contents/memory-bank/{name}")
            import base64
            bank[name] = base64.b64decode(file_data["content"]).decode("utf-8")
        except Exception:
            bank[name] = ""
    return bank
```

- [ ] **Step 3: Add `_write_memory_bank()` method**

Add directly after `_read_memory_bank()`:

```python
def _write_memory_bank(
    self,
    updated_bank: dict[str, str],
    gh: "GitHubClient",
    branch: str,
) -> None:
    """Commit updated memory bank files to the feature branch."""
    if not updated_bank:
        return
    for name, content in updated_bank.items():
        try:
            gh.commit_file(
                f"memory-bank/{name}",
                content,
                f"memory: update {name} after pipeline run",
                branch,
            )
            console.print(f"  🧠 [dim]Memory bank updated: {name}[/dim]")
        except Exception as exc:
            console.print(f"  [yellow]⚠️  Failed to update memory-bank/{name}: {exc}[/yellow]")
```

- [ ] **Step 4: Add memory bank update in `_finish()`**

In `_finish()`, find the block that ends with `self._maybe_consolidate(active_repo)` (around line 730). After that line, still inside the outer `try:` block, add:

```python
            # ── Update memory bank in target repo ─────────────────────────
            if self.target_github and hasattr(result, "branch") and result.branch:
                try:
                    current_bank = self._read_memory_bank(self.target_github)
                    updater = MemoryBankUpdaterAgent(
                        model=_model("memory_bank_updater"),
                        github_token=self._github_token,
                    )
                    updated_bank = updater.update(current_bank, summary_text)
                    self._write_memory_bank(updated_bank, self.target_github, result.branch)
                except Exception as exc:
                    console.print(f"  [yellow]⚠️  Memory bank update failed: {exc}[/yellow]")
```

Note: `_model()` is a local function in `_finish()` or at module level — check how SummaryAgent's model is retrieved:

```bash
grep -n "_model\|\"summariser\"\|config\[" /home/wanleung/Projects/ai-software-house/orchestrator.py | head -20
```

Use the same pattern.

- [ ] **Step 5: Verify `result.branch` is available at the memory bank update point**

```bash
grep -n "result\.branch\s*=\|result\.branch" /home/wanleung/Projects/ai-software-house/orchestrator.py | head -20
```

`result.branch` should be set by the code generation stage when a PR branch is created. If it isn't set in short-circuit paths (failed earlier stages), the `hasattr` guard will protect against errors.

- [ ] **Step 6: Smoke-test import**

```bash
cd /home/wanleung/Projects/ai-software-house
source venv/bin/activate 2>/dev/null || true
python -c "from orchestrator import Orchestrator; print('Orchestrator imports OK')"
```

Expected: `Orchestrator imports OK`

- [ ] **Step 7: Commit**

```bash
cd /home/wanleung/Projects/ai-software-house
git add orchestrator.py
git commit -m "feat: wire MemoryBankUpdaterAgent into pipeline

Reads memory bank via GitHub API, updates after SummaryAgent completes,
commits to feature branch. Errors are non-blocking.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 7: Push copilot-agent-setting to remote

- [ ] **Step 1: Push all commits**

```bash
cd /home/wanleung/Projects/copilot-agent-setting
git push origin master
```

Expected: clean push with the new `memory-bank/`, `.github/`, deploy scripts, and updater role.

- [ ] **Step 2: Verify remote has files**

```bash
git ls-remote origin HEAD
```

---

## Self-Review Notes

- **Spec coverage:** All spec sections covered: template files (Task 1), `.github/copilot-instructions.md` (Task 2), deploy scripts (Task 2), `MemoryBankUpdaterAgent` role + code (Tasks 3 & 5), orchestrator wiring for both systems (Tasks 4 & 6).
- **No placeholders:** All code blocks are complete and runnable.
- **Type consistency:** `dict[str, str]` used consistently for `current_bank` and `updated_bank`. `commit_file(path, content, message, branch)` matches the existing GitHubClient signature in both projects.
- **Error handling:** All memory bank operations are wrapped in try/except; failures log a warning and continue — never block the pipeline.
- **ai-software-house `_model()` note:** Task 6 Step 4 includes a verification step to check the model-lookup pattern before writing code. This prevents a type error if the pattern differs from copilot-software-house.
