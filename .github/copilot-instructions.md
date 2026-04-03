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
