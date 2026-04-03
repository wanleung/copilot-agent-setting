# Copilot Agent Instructions

This directory contains system-prompt files for each AI software house agent.
Load the relevant file at the start of a Copilot session to give Copilot the
correct role, responsibilities, and output format.

## How to use in a Copilot chat session

Paste the contents of the relevant file as your first message, then follow
with your task. Example:

```markdown
[paste contents of agents/product_manager.md]

---

TASK: Build a fuel price comparison app for UK petrol stations.
```

---

## Pipeline order

Run agents in this sequence for a full feature build:

| Stage | Agent file              | What it produces                                       |
| ----- | ----------------------- | ------------------------------------------------------ |
| 1     | `agents/product_manager.md`    | PRD — user stories, requirements, scope                |
| 1b    | `agents/pm_reviewer.md`        | PRD review — APPROVED or NEEDS REVISION                |
| 2     | `agents/architect.md`          | System design — modules, API, file structure           |
| 2b    | `agents/architect_reviewer.md` | Design review — APPROVED or NEEDS REVISION             |
| 3     | `agents/engineer.md`           | Code — full implementation of one module               |
| 4     | `agents/code_reviewer.md`      | Code review — issues and approval verdict              |
| 4b    | `agents/qa_planner.md`         | Test plan — acceptance criteria and scenarios          |
| 5     | `agents/qa_engineer.md`        | Automated tests — pytest files, conftest, requirements |
| 6     | `agents/deployment_tester.md`  | Smoke tests — docker-compose, deploy script            |

### Utility agents (use any time)

| Agent file               | Purpose                                                |
| ------------------------ | ------------------------------------------------------ |
| `agents/summariser.md`          | Summarise a completed run into a compact memory entry  |
| `agents/refactor_agent.md`      | Analyse existing code and produce a cleanup plan       |
| `agents/memory_consolidator.md` | Roll up multiple run summaries into a monthly snapshot |

---

## Skills & MCP tools

Agents in this pipeline have access to four shared tools, available two ways:

| Integration | How it works | Best for |
|---|---|---|
| **MCP server** (`skills-mcp/`) | Copilot CLI calls tools via Model Context Protocol | Copilot CLI sessions |
| **Python registry** (`skills/`) | Tools imported directly into agent code | Custom Python pipelines |

See [`skills/skills-reference.md`](skills/skills-reference.md) for full tool documentation.
See [`skills-mcp/README.md`](skills-mcp/README.md) for MCP setup instructions.

---

## Tips

- **Pass output forward**: paste the PRD output as input to the Architect,
  paste the design as input to the Engineer, and so on.
- **Revision loop**: if a reviewer returns NEEDS REVISION, paste the review
  feedback alongside the original requirements back into the upstream agent.
- **Multiple engineers**: run `agents/engineer.md` once per module in parallel
  Copilot sessions, each given a different module from the design.
- **Memory**: after a run, use `agents/summariser.md` to produce a compact entry,
  then paste it at the top of your next session as context.
