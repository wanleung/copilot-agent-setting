# Agent Skills Reference

These are the built-in tools available to any AI software house agent.
They are defined in `builtin_tools.py` and registered via `tool_registry.py`.

Agents call these tools through the `call_with_tools()` method on `BaseAgent`
(ai-software-house) or by injecting them into the prompt (copilot-software-house).

---

## run_linter

Run the **ruff** linter on Python source code and return any lint errors.

| Parameter  | Type   | Required | Description                               |
| ---------- | ------ | -------- | ----------------------------------------- |
| `code`     | string | ✅       | Full Python source code to lint           |
| `filename` | string | ❌       | Filename for context (e.g. `src/main.py`) |

**Returns:** Lint errors as text, or `✅ No lint errors found.`

**Example use:** Code Reviewer calls this before writing a review to get
objective lint data rather than guessing at style issues.

---

## run_shell_command

Run a safe shell command and return stdout + stderr (max 4000 chars).

| Parameter | Type     | Required | Description                                          |
| --------- | -------- | -------- | ---------------------------------------------------- |
| `command` | string[] | ✅       | Command as a list, e.g. `["pytest", "tests/", "-v"]` |
| `cwd`     | string   | ❌       | Working directory                                    |

**Returns:** Combined stdout + stderr, truncated at 4000 chars.

**Blocked commands:** `rm`, `rmdir`, `dd`, `mkfs`, `shutdown`, `reboot`, `curl`, `wget`

**Example use:** QA Engineer runs `pytest tests/ -v` to verify tests pass
before submitting the test plan.

---

## search_github_issues

Search GitHub issues in a repository.

| Parameter | Type   | Required | Description                                 |
| --------- | ------ | -------- | ------------------------------------------- |
| `repo`    | string | ✅       | `owner/repo` format                         |
| `query`   | string | ✅       | Search keywords                             |
| `state`   | string | ❌       | `open` / `closed` / `all` (default: `open`) |

**Returns:** JSON list of up to 5 matching issues with number, title, state,
URL, and body snippet.

**Example use:** Product Manager searches for existing issues before writing
a PRD to avoid duplicating work already in the backlog.

---

## get_github_file

Read the raw content of a file from a GitHub repository.

| Parameter | Type   | Required | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `repo`    | string | ✅       | `owner/repo` format                  |
| `path`    | string | ✅       | File path within the repo            |
| `ref`     | string | ❌       | Branch / tag / SHA (default: `main`) |

**Returns:** File content as a string, truncated at 6000 chars.

**Example use:** Architect fetches the existing `README.md` or `config.yaml`
to understand what's already in the repo before designing new modules.

---

## How to wire tools to an agent (ai-software-house)

```python
from skills.builtin_tools import builtin_tools
from agents.code_reviewer import CodeReviewerAgent

reviewer = CodeReviewerAgent()
result = reviewer.call_with_tools(
    "Review this code:\n\n" + code,
    tools=builtin_tools,
)
```

## How to describe tools to Copilot CLI (copilot-software-house)

Since Copilot CLI agents are stateless subprocesses, inject a tools summary
into the prompt:

```text
[AVAILABLE TOOLS]
- run_linter(code, filename?) — run ruff on Python code
- run_shell_command(command[], cwd?) — run pytest, check syntax, etc.
- search_github_issues(repo, query, state?) — search GitHub issues
- get_github_file(repo, path, ref?) — read a file from GitHub

To use a tool, output:
TOOL_CALL: <tool_name> <json_arguments>
```

## How to use tools via Copilot CLI MCP (recommended)

The `skills-mcp/` directory contains an MCP server that exposes all four tools
natively to Copilot CLI. This is the preferred integration — no prompt injection
needed; Copilot calls the tools directly.

See [`skills-mcp/README.md`](../skills-mcp/README.md) for setup instructions.

---

## Adding a new skill

1. Register it in `builtin_tools.py` using the `@builtin_tools.tool(...)` decorator
2. Mirror it in `skills-mcp/server.py` using the `@mcp.tool()` decorator
3. Add a row to this reference doc
4. Mention it in the relevant agent's role file under a `## Available Tools` section
