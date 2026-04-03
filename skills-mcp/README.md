# Skills MCP Server

An MCP server that exposes the agent skills from `skills/builtin_tools.py` so that **Copilot CLI** (and any MCP-compatible client) can call them natively via the Model Context Protocol.

## Why MCP?

The `skills/` folder originally used a custom Python `LocalToolRegistry` and a `TOOL_CALL:` prompt-injection pattern for stateless agents. The MCP server replaces that with a proper protocol-level integration — Copilot CLI calls the tools directly without any prompt hacking.

## Tools

| Tool | Parameters | Description |
|---|---|---|
| `run_linter` | `code` (required), `filename` (optional) | Run ruff on Python source; returns lint errors or ✅ |
| `run_shell_command` | `command[]` (required), `cwd` (optional) | Run a safe shell command; blocked: `rm`, `rmdir`, `dd`, `mkfs`, `shutdown`, `reboot`, `curl`, `wget` |
| `search_github_issues` | `repo`, `query` (required), `state` (optional) | Search GitHub issues; returns up to 5 results as JSON |
| `get_github_file` | `repo`, `path` (required), `ref` (optional) | Read a raw file from GitHub; truncated at 6000 chars |

> `search_github_issues` and `get_github_file` require a `GITHUB_TOKEN` environment variable.

## Setup

```bash
cd skills-mcp
pip install -r requirements.txt
```

## Add to Copilot CLI

### Option A — `/mcp` command (interactive)

1. Launch Copilot CLI
2. Run `/mcp` → select **Add server**
3. Enter the path to `server.py` and set `GITHUB_TOKEN` when prompted

### Option B — edit config directly

Edit `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "skills": {
      "command": "python",
      "args": ["/absolute/path/to/skills-mcp/server.py"],
      "env": {
        "GITHUB_TOKEN": "your_token_here"
      }
    }
  }
}
```

Then restart Copilot CLI. All four tools will be available to the agent automatically.

## Test locally

```bash
# Interactive inspector — lists tools and lets you call them manually
mcp dev server.py

# Quick smoke test (no GitHub token needed for these two)
python -c "
import server
tools = server.mcp._tool_manager.list_tools()
for t in tools:
    print(f'  ✅ {t.name}')
"
```

## File structure

```
skills-mcp/
├── server.py          # FastMCP server — all 4 tools defined here
├── requirements.txt   # mcp[cli], httpx, ruff
└── README.md          # this file
```

## Adding a new tool

1. Add a `@mcp.tool()` function in `server.py`
2. Mirror it in `skills/builtin_tools.py` for the non-MCP pipeline
3. Document it in `skills/skills-reference.md`

