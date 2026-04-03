# Copilot Agent Settings

Shared config and templates for AI Software House Copilot CLI sessions.

This repository is the single source of truth for agent role prompts, memory bank
templates, and helper scripts used by the `copilot-software-house` and
`ai-software-house` orchestration pipelines.

---

## What's in here

| Path | Purpose |
| ---- | ------- |
| `.github/copilot-instructions.md` | Auto-loaded by Copilot CLI; tells it to read the Memory Bank at session start |
| `memory-bank/` | 6 Markdown template files that give Copilot persistent memory across sessions |
| `agents/` | 13 system-prompt files — one per pipeline agent role |
| `skills/` | Python tool files (`builtin_tools.py`, `tool_registry.py`) for agent capabilities |
| `deploy-memory-bank.sh` | Copies `memory-bank/` and `copilot-instructions.md` into any target project |
| `update-memory-bank.sh` | Manual memory bank update triggered via Copilot CLI |
| `install-memory-bank-hook.sh` | Installs a git post-commit hook that semi-automatically updates the memory bank |
| `docs/superpowers/` | Design specs and plans for the superpowers skill system |

---

## Memory Bank

The Memory Bank is the most important concept in this repo. It gives Copilot
persistent, structured context across sessions — so it always knows what the
project is, how it is architected, and where work currently stands.

It is inspired by [Cline's Memory Bank](https://github.com/cline/cline/discussions/1784)
pattern, adapted for Copilot CLI.

### The 6 files and their hierarchy

The files form a deliberate reading order from stable context to current state:

```text
projectbrief.md          ← why the project exists; goals and scope
  └── productContext.md  ← user problems, UX goals, success criteria
        ├── systemPatterns.md  ← architecture, patterns, conventions
        ├── techContext.md     ← tech stack, dependencies, environment
        └── activeContext.md   ← current focus, recent changes, next steps
              └── progress.md  ← what's done, in-progress, blocked
```

`projectbrief.md` and `productContext.md` are filled in once and rarely change.
`activeContext.md` and `progress.md` are updated after every significant session.

### Setup — deploy to a project

Run this once per project:

```bash
cd /path/to/copilot-agent-setting
./deploy-memory-bank.sh /path/to/your-project
```

This copies the 6 template files into `your-project/memory-bank/` and writes
`.github/copilot-instructions.md` so Copilot reads them automatically.

Then edit the two foundation files for your project:

```bash
# Fill these in before starting any work
your-project/memory-bank/projectbrief.md
your-project/memory-bank/productContext.md
```

### Three update modes

#### Fully automatic

Both `copilot-software-house` and `ai-software-house` orchestrators automatically
call the `memory_bank_updater` agent after every pipeline run, keeping all 6 files
up to date without any manual steps.

#### Semi-automatic (git hook)

Install once per project. After that, every `git commit` automatically updates
`activeContext.md` and `progress.md`:

```bash
cd /path/to/copilot-agent-setting
./install-memory-bank-hook.sh /path/to/your-project
```

#### Manual

Run from inside your project directory, passing a short description of what changed:

```bash
./update-memory-bank.sh "Added JWT authentication to /api/auth"
```

### How Copilot reads it

`deploy-memory-bank.sh` writes `.github/copilot-instructions.md` into your project.
Copilot CLI auto-loads that file at the start of every session. It instructs Copilot
to read all 6 memory bank files in order before doing anything else, so full project
context is always available from the first message.

---

## Agent Roles

The `agents/` directory contains 13 system-prompt files. Each file defines the
persona, responsibilities, and output format for one stage of the AI Software House
pipeline.

| File | Role |
| ---- | ---- |
| `product_manager.md` | Turns raw requirements into a structured PRD with user stories and acceptance criteria |
| `pm_reviewer.md` | Reviews PRDs for completeness, clarity, and testability before design begins |
| `architect.md` | Produces system design (data models, API contracts, module breakdown) from a PRD |
| `architect_reviewer.md` | Reviews designs for completeness, correctness, and feasibility |
| `engineer.md` | Implements modules from a system design, writing clean production code |
| `code_reviewer.md` | Reviews code for bugs, security vulnerabilities, and quality |
| `qa_planner.md` | Writes a comprehensive test plan from acceptance criteria |
| `qa_engineer.md` | Writes immediately runnable pytest test suites covering all layers |
| `deployment_tester.md` | Writes deployment smoke tests and docker-compose test configs |
| `summariser.md` | Writes a compact, factual memory entry after each pipeline run |
| `memory_bank_updater.md` | Updates the 6 memory bank files after each run |
| `memory_consolidator.md` | Compresses multiple run summaries into a single snapshot |
| `refactor_agent.md` | Reviews and rewrites code for readability and maintainability |

---

## Using with copilot-software-house / ai-software-house

Both orchestrator systems read agent role files directly from this repository.
When a pipeline run kicks off, each stage loads its corresponding file from
`agents/` as its system prompt, so every agent operates with a consistent and
well-defined persona. At the end of each run the orchestrator calls
`memory_bank_updater` to keep the Memory Bank in the target project current —
meaning the next session (human or automated) always starts with accurate context.

---

## License

MIT
