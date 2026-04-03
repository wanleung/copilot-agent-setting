"""
Skills MCP Server

Exposes the same tools as skills/builtin_tools.py as an MCP server,
so Copilot CLI (and any MCP-compatible client) can call them natively.

Tools:
  - run_linter          Run ruff on Python source code
  - run_shell_command   Run a safe shell command
  - search_github_issues  Search GitHub issues in a repo
  - get_github_file     Read a file from a GitHub repository
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import httpx
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("skills")


# ── Code quality tools ────────────────────────────────────────────────────────

@mcp.tool()
def run_linter(code: str, filename: str = "code.py") -> str:
    """Run the ruff linter on Python source code and return any lint errors.

    Args:
        code: Full Python source code to lint.
        filename: Filename for context (e.g. 'src/main.py').
    """
    suffix = Path(filename).suffix or ".py"
    with tempfile.NamedTemporaryFile(mode="w", suffix=suffix, delete=False) as f:
        f.write(code)
        tmp = f.name
    try:
        result = subprocess.run(
            [sys.executable, "-m", "ruff", "check", tmp, "--output-format=text"],
            capture_output=True,
            text=True,
        )
        output = result.stdout + result.stderr
        output = output.replace(tmp, filename)
        return output.strip() or "✅ No lint errors found."
    finally:
        os.unlink(tmp)


@mcp.tool()
def run_shell_command(command: list[str], cwd: str | None = None) -> str:
    """Run a safe shell command and return stdout + stderr (max 4000 chars).

    Blocked commands: rm, rmdir, dd, mkfs, shutdown, reboot, curl, wget

    Args:
        command: Command as a list of strings, e.g. ['pytest', 'tests/', '-v'].
        cwd: Working directory (optional).
    """
    blocked = {"rm", "rmdir", "dd", "mkfs", "shutdown", "reboot", "curl", "wget"}
    if command and command[0].lower() in blocked:
        return f"[Blocked] Command '{command[0]}' is not allowed."
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=30,
            cwd=cwd,
        )
        output = (result.stdout + result.stderr).strip()
        if len(output) > 4000:
            output = output[:4000] + "\n… [truncated]"
        return output or "(no output)"
    except subprocess.TimeoutExpired:
        return "[Error] Command timed out after 30s."
    except FileNotFoundError:
        return f"[Error] Command not found: {command[0]!r}"


# ── GitHub tools ──────────────────────────────────────────────────────────────

def _gh_headers() -> dict:
    token = os.environ.get("GITHUB_TOKEN", "")
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


@mcp.tool()
def search_github_issues(repo: str, query: str, state: str = "open") -> str:
    """Search GitHub issues in a repository.

    Returns up to 5 matching issues with number, title, state, URL, and body snippet.

    Args:
        repo: Repository in 'owner/repo' format.
        query: Search keywords.
        state: Issue state — 'open', 'closed', or 'all' (default: 'open').
    """
    url = "https://api.github.com/search/issues"
    params = {"q": f"{query} repo:{repo} is:issue state:{state}", "per_page": 5}
    resp = httpx.get(url, headers=_gh_headers(), params=params, timeout=10)
    if not resp.is_success:
        return f"[Error] GitHub search failed: {resp.status_code} {resp.text[:200]}"
    items = resp.json().get("items", [])
    if not items:
        return "No matching issues found."
    results = [
        {
            "number": i["number"],
            "title": i["title"],
            "state": i["state"],
            "url": i["html_url"],
            "body_snippet": (i.get("body") or "")[:300],
        }
        for i in items
    ]
    return json.dumps(results, indent=2)


@mcp.tool()
def get_github_file(repo: str, path: str, ref: str = "main") -> str:
    """Read the content of a file from a GitHub repository.

    Args:
        repo: Repository in 'owner/repo' format.
        path: File path within the repository.
        ref: Branch, tag, or commit SHA (default: 'main').
    """
    url = f"https://raw.githubusercontent.com/{repo}/{ref}/{path}"
    resp = httpx.get(url, headers=_gh_headers(), timeout=10)
    if not resp.is_success:
        return f"[Error] Could not fetch {path}: {resp.status_code}"
    content = resp.text
    if len(content) > 6000:
        content = content[:6000] + "\n… [truncated]"
    return content


if __name__ == "__main__":
    mcp.run()
