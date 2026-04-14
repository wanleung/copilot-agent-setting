# Ollama Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Ollama as a first-class LLM backend to both `ai-software-house` and `copilot-software-house`, selectable via `ollama/<model>` prefix in model names and configured via a gitignored `config.local.yaml`.

**Architecture:** Two independent sets of changes — one per repo. Both share the same patterns: a `_deep_merge()` helper for config layering, an `ollama_url` parameter threaded to BaseAgent, and Ollama detection via model name prefix. ai-software-house reuses its existing OpenAI SDK client path; copilot-software-house adds a new `_run_ollama()` method alongside its subprocess path.

**Tech Stack:** Python, PyYAML, `openai` SDK (OpenAI-compatible Ollama API at `/v1`), pytest

---

## File Map

### ai-software-house

| Action | File | Purpose |
| --- | --- | --- |
| Create | `tests/test_ollama.py` | Unit tests for Ollama detection and deep_merge |
| Modify | `agents/base_agent.py` | Add `_is_ollama_model()`, `ollama_url` param, ollama backend branch |
| Modify | `orchestrator.py` | Add `_deep_merge()`, load `config.local.yaml`, pass `ollama_url` |
| Modify | `config.yaml` | Add `ollama_url` key and Ollama model examples |
| Modify | `.gitignore` | Add `config.local.yaml` |
| Modify | `README.md` | Add Ollama setup section |

### copilot-software-house

| Action | File | Purpose |
| --- | --- | --- |
| Create | `tests/test_ollama.py` | Unit tests for `_run_ollama`, `_deep_merge`, routing |
| Modify | `agents/base_agent.py` | Add `ollama_url` param, `_run_ollama()`, branch in `_run()` |
| Modify | `orchestrator.py` | Add `_deep_merge()`, load `config.local.yaml`, set `ollama_url` on agents |
| Modify | `config.yaml` | Add `ollama_url` key and Ollama model examples |
| Modify | `.gitignore` | Add `config.local.yaml` |
| Modify | `requirements.txt` | Add `openai>=1.0` |
| Modify | `README.md` | Add Ollama setup section |

---

## Part A — ai-software-house

Work from: `/home/wanleung/Projects/ai-software-house`

---

### Task 1: Tests + `_deep_merge` + Ollama backend detection (ai-software-house)

**Files:**
- Create: `tests/__init__.py` (if not exists)
- Create: `tests/test_ollama.py`
- Modify: `orchestrator.py` (add `_deep_merge`)
- Modify: `agents/base_agent.py` (add `_is_ollama_model`)

- [ ] **Step 1: Create `tests/__init__.py` if missing**

```bash
mkdir -p tests && touch tests/__init__.py
```

- [ ] **Step 2: Create `tests/test_ollama.py`**

Create the file with this content:

```python
"""Unit tests for Ollama support in ai-software-house."""
import pytest
from unittest.mock import MagicMock, patch


# ── _deep_merge ──────────────────────────────────────────────────────────────

def test_deep_merge_non_overlapping_keys():
    from orchestrator import _deep_merge
    result = _deep_merge({"a": 1}, {"b": 2})
    assert result == {"a": 1, "b": 2}


def test_deep_merge_override_scalar():
    from orchestrator import _deep_merge
    result = _deep_merge({"a": 1}, {"a": 99})
    assert result == {"a": 99}


def test_deep_merge_nested_merge():
    from orchestrator import _deep_merge
    base = {"llm": {"model": "gpt-4.1", "overrides": {"engineer": "gpt-4.1-mini"}}}
    override = {"llm": {"ollama_url": "http://10.0.0.1:11434", "overrides": {"engineer": "ollama/qwen2.5-coder"}}}
    result = _deep_merge(base, override)
    assert result["llm"]["model"] == "gpt-4.1"
    assert result["llm"]["ollama_url"] == "http://10.0.0.1:11434"
    assert result["llm"]["overrides"]["engineer"] == "ollama/qwen2.5-coder"


def test_deep_merge_does_not_mutate_base():
    from orchestrator import _deep_merge
    base = {"a": {"b": 1}}
    _deep_merge(base, {"a": {"c": 2}})
    assert base == {"a": {"b": 1}}


# ── _is_ollama_model ─────────────────────────────────────────────────────────

def test_is_ollama_model_with_prefix():
    from agents.base_agent import _is_ollama_model
    assert _is_ollama_model("ollama/llama3.2") is True
    assert _is_ollama_model("ollama/qwen2.5-coder") is True


def test_is_ollama_model_without_prefix():
    from agents.base_agent import _is_ollama_model
    assert _is_ollama_model("openai/gpt-4.1") is False
    assert _is_ollama_model("claude-3-5-sonnet-20241022") is False
    assert _is_ollama_model("gpt-4o") is False


# ── BaseAgent Ollama backend ──────────────────────────────────────────────────

def test_base_agent_ollama_backend_sets_api_model():
    """BaseAgent strips 'ollama/' prefix and stores bare model name."""
    with patch("agents.base_agent.OpenAI") as mock_openai_cls:
        mock_openai_cls.return_value = MagicMock()
        from agents.base_agent import BaseAgent
        agent = BaseAgent(model="ollama/llama3.2", ollama_url="http://localhost:11434")
        assert agent._backend == "ollama"
        assert agent._api_model == "llama3.2"


def test_base_agent_ollama_client_uses_ollama_url():
    """BaseAgent initialises OpenAI client with Ollama base_url."""
    with patch("agents.base_agent.OpenAI") as mock_openai_cls:
        mock_openai_cls.return_value = MagicMock()
        from agents.base_agent import BaseAgent
        agent = BaseAgent(model="ollama/llama3.2", ollama_url="http://10.0.0.1:11434")
        mock_openai_cls.assert_called_once_with(
            base_url="http://10.0.0.1:11434/v1",
            api_key="ollama",
        )


def test_base_agent_github_models_api_model_unchanged():
    """GitHub Models backend: _api_model is the full model string."""
    with patch.dict("os.environ", {"GITHUB_TOKEN": "ghp_fake"}):
        import importlib
        import agents.base_agent as ba_module
        importlib.reload(ba_module)
        agent = ba_module.BaseAgent(model="openai/gpt-4.1")
        assert agent._backend == "github_models"
        assert agent._api_model == "openai/gpt-4.1"
```

- [ ] **Step 3: Run tests — expect failures (imports missing)**

```bash
cd /home/wanleung/Projects/ai-software-house && python -m pytest tests/test_ollama.py -v 2>&1 | tail -30
```

Expected: failures like `ImportError: cannot import name '_deep_merge' from 'orchestrator'` and `ImportError: cannot import name '_is_ollama_model' from 'agents.base_agent'`

- [ ] **Step 4: Add `_deep_merge` to `orchestrator.py`**

Find the top of `orchestrator.py` (after imports, before class definitions). Add:

```python
def _deep_merge(base: dict, override: dict) -> dict:
    """Recursively merge override into base, returning a new dict.

    Nested dicts are merged at the leaf level; scalars are overwritten.
    Neither input dict is mutated.
    """
    result = dict(base)
    for key, val in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(val, dict):
            result[key] = _deep_merge(result[key], val)
        else:
            result[key] = val
    return result
```

- [ ] **Step 5: Add `_is_ollama_model` to `agents/base_agent.py`**

Find the line `def _is_anthropic_model(model: str) -> bool:` and add below it:

```python
def _is_ollama_model(model: str) -> bool:
    return model.startswith("ollama/")
```

- [ ] **Step 6: Run the detection tests — expect partial pass**

```bash
cd /home/wanleung/Projects/ai-software-house && python -m pytest tests/test_ollama.py::test_deep_merge_non_overlapping_keys tests/test_ollama.py::test_deep_merge_override_scalar tests/test_ollama.py::test_deep_merge_nested_merge tests/test_ollama.py::test_deep_merge_does_not_mutate_base tests/test_ollama.py::test_is_ollama_model_with_prefix tests/test_ollama.py::test_is_ollama_model_without_prefix -v
```

Expected: 6 PASS. The `BaseAgent` tests will still fail — that's fine.

- [ ] **Step 7: Add Ollama backend to `BaseAgent.__init__` in `agents/base_agent.py`**

Find the `__init__` signature and add `ollama_url: str = "http://localhost:11434"`:

```python
def __init__(
    self,
    model: str = "gpt-4.1",
    github_token: Optional[str] = None,
    roles_dir: Optional[Path] = None,
    backend: Optional[str] = None,
    ollama_url: str = "http://localhost:11434",
) -> None:
```

Then find the backend detection block (the `use_anthropic = ...` line) and replace it with:

```python
        # Auto-detect backend from model name if not explicitly set
        use_anthropic = (backend == "anthropic") or (
            backend is None and _is_anthropic_model(model)
        )
        use_ollama = (backend == "ollama") or (
            backend is None and _is_ollama_model(model)
        )

        if use_anthropic:
            api_key = os.environ.get("ANTHROPIC_API_KEY")
            if not api_key:
                raise EnvironmentError(
                    "ANTHROPIC_API_KEY environment variable is required for Claude models. "
                    "Get your key at https://console.anthropic.com/"
                )
            import anthropic as _anthropic
            self._anthropic_client = _anthropic.Anthropic(api_key=api_key)
            self._backend = "anthropic"
            self.client = None
            self._api_model = model
        elif use_ollama:
            from openai import OpenAI
            self._backend = "ollama"
            self._api_model = model.removeprefix("ollama/")
            self.client = OpenAI(base_url=f"{ollama_url}/v1", api_key="ollama")
            self._anthropic_client = None
        else:
            from openai import OpenAI
            token = github_token or os.environ.get("GITHUB_TOKEN")
            if not token:
                raise EnvironmentError(
                    "GITHUB_TOKEN environment variable is required. "
                    "Create a token at https://github.com/settings/personal-access-tokens/new "
                    "with 'Copilot Requests', 'Contents', 'Issues', and 'Pull requests' permissions."
                )
            self.client = OpenAI(
                base_url="https://models.github.ai/inference",
                api_key=token,
            )
            self._backend = "github_models"
            self._api_model = model
            self._anthropic_client = None
```

- [ ] **Step 8: Update the `client.chat.completions.create` call to use `self._api_model`**

Find the line `model=self.model,` inside the GitHub Models call block and change it to:

```python
                response = self.client.chat.completions.create(
                    model=self._api_model,
                    messages=messages,
                    temperature=0.3,
                )
```

- [ ] **Step 9: Run all Ollama tests — expect all pass**

```bash
cd /home/wanleung/Projects/ai-software-house && python -m pytest tests/test_ollama.py -v
```

Expected: all tests PASS.

- [ ] **Step 10: Commit**

```bash
cd /home/wanleung/Projects/ai-software-house
git add tests/ agents/base_agent.py orchestrator.py
git commit -m "feat: add Ollama backend detection and _deep_merge helper

- _is_ollama_model(): detects 'ollama/' prefix
- BaseAgent: ollama backend branch, ollama_url param, _api_model field
- _deep_merge(): recursive config merge for config.local.yaml support

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Wire Ollama config loading in ai-software-house Orchestrator

**Files:**
- Modify: `orchestrator.py` (`from_config` and `__init__`)

- [ ] **Step 1: Load `config.local.yaml` in `from_config()`**

Find the `from_config` classmethod. After the `cfg = yaml.safe_load(f)` line, add:

```python
        # Layer config.local.yaml (gitignored) on top — for local overrides like ollama_url
        local_path = Path(config_path).parent / "config.local.yaml"
        if local_path.exists():
            with open(local_path, encoding="utf-8") as lf:
                local_cfg = yaml.safe_load(lf) or {}
            cfg = _deep_merge(cfg, local_cfg)
```

- [ ] **Step 2: Extract `ollama_url` and thread it through `Orchestrator.__init__`**

In `from_config`, find where `llm = cfg.get("llm", {})` is and add:

```python
        ollama_url = llm.get("ollama_url", "http://localhost:11434")
```

Then add it to the `return cls(...)` call:

```python
        return cls(
            model=llm.get("model", "gpt-4.1"),
            github_repo=repo if use_github else None,
            github_token=github_token,
            num_engineers=team.get("num_engineers", 2),
            branch_prefix=gh.get("branch_prefix", "feature/agent"),
            workspace_dir=pipeline.get("workspace_dir", "./workspace"),
            stop_on_review_issues=pipeline.get("stop_on_review_issues", False),
            model_overrides=llm.get("overrides", {}),
            use_github=use_github,
            ollama_url=ollama_url,
        )
```

- [ ] **Step 3: Add `ollama_url` to `Orchestrator.__init__` signature and `agent_kwargs`**

Find the `__init__` signature and add the parameter:

```python
    def __init__(
        self,
        model: str = "gpt-4.1",
        github_repo: Optional[str] = None,
        github_token: Optional[str] = None,
        num_engineers: int = 2,
        branch_prefix: str = "feature/agent",
        workspace_dir: str = "./workspace",
        stop_on_review_issues: bool = False,
        model_overrides: Optional[dict] = None,
        use_github: bool = False,
        target_repo: Optional[str] = None,
        ollama_url: str = "http://localhost:11434",
    ) -> None:
```

Find `agent_kwargs = {"github_token": github_token}` and change it to:

```python
        agent_kwargs = {"github_token": github_token, "ollama_url": ollama_url}
```

- [ ] **Step 4: Verify orchestrator imports properly**

```bash
cd /home/wanleung/Projects/ai-software-house && python -c "from orchestrator import Orchestrator, _deep_merge; print('OK')"
```

Expected: `OK`

- [ ] **Step 5: Run all Ollama tests to confirm nothing broken**

```bash
cd /home/wanleung/Projects/ai-software-house && python -m pytest tests/test_ollama.py -v
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
cd /home/wanleung/Projects/ai-software-house
git add orchestrator.py
git commit -m "feat: load config.local.yaml and pass ollama_url to agents

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Config, gitignore, README for ai-software-house

**Files:**
- Modify: `config.yaml`
- Modify: `.gitignore`
- Modify: `README.md`

- [ ] **Step 1: Add `ollama_url` and Ollama model examples to `config.yaml`**

Find the `llm:` section. Add `ollama_url` after the `model:` line and Ollama examples in the comments:

```yaml
llm:
  # Default model for all agents (used when no per-agent override is set)
  #
  # ── GitHub Models API (GITHUB_TOKEN required) ──────────────────────────
  #   OpenAI   : openai/gpt-4.1, openai/gpt-4.1-mini, openai/gpt-4.1-nano
  #   Mistral  : mistral-ai/mistral-small-2503
  #   DeepSeek : deepseek/deepseek-r1
  #   Meta     : meta-llama-3.1-405b-instruct
  #
  # ── Anthropic Claude API (ANTHROPIC_API_KEY required) ──────────────────
  #   claude-3-5-sonnet-20241022   (fast, smart — recommended)
  #   claude-3-7-sonnet-20250219   (extended thinking)
  #   claude-3-5-haiku-20241022    (fastest, cheapest)
  #   claude-3-opus-20240229       (most capable)
  #
  # ── Ollama (local — no API key required) ──────────────────────────────
  #   ollama/llama3.2              (general purpose)
  #   ollama/qwen2.5-coder         (code-focused, recommended for engineer role)
  #   ollama/mistral               (fast, lightweight)
  #
  # Claude models are auto-detected by name prefix "claude-" and will use
  # the Anthropic API automatically. Ollama models are auto-detected by
  # the "ollama/" prefix and use the Ollama server at ollama_url below.
  model: "openai/gpt-4.1"

  # Ollama server URL. Override in config.local.yaml for non-default hosts.
  # config.local.yaml is gitignored — safe for private network addresses.
  ollama_url: "http://localhost:11434"
```

- [ ] **Step 2: Add `config.local.yaml` to `.gitignore`**

Open `.gitignore` and add:

```
config.local.yaml
```

- [ ] **Step 3: Find the Ollama section in README.md and add setup instructions**

Find or create a `## Ollama (Local Models)` section in `README.md`. Add after the existing LLM/API section:

```markdown
## Ollama (Local Models)

Run agents entirely locally — no API keys, no cloud costs, full privacy.

### Prerequisites

1. Install Ollama: <https://ollama.com>
2. Pull a model:
   ```bash
   ollama pull llama3.2          # general purpose
   ollama pull qwen2.5-coder     # recommended for engineer role
   ```
3. Start the Ollama server (runs automatically after install):
   ```bash
   ollama serve
   ```

### Configuration

Set models with the `ollama/` prefix in `config.yaml` or per-agent overrides:

```yaml
llm:
  model: "ollama/llama3.2"        # use Ollama for all agents
  overrides:
    engineer: "ollama/qwen2.5-coder"   # use code-focused model for engineer
```

To use a non-default Ollama server (e.g. on your local network), create
`config.local.yaml` in the project root — it is gitignored and never committed:

```yaml
# config.local.yaml — gitignored, never committed
llm:
  ollama_url: "http://10.100.1.30:11434"
```

Mix Ollama with cloud models freely — each agent can use a different backend:

```yaml
llm:
  model: "openai/gpt-4.1"                  # default: cloud
  ollama_url: "http://localhost:11434"
  overrides:
    engineer: "ollama/qwen2.5-coder"        # engineer: local
    qa_engineer: "ollama/llama3.2"          # QA: local
```
```

- [ ] **Step 4: Commit**

```bash
cd /home/wanleung/Projects/ai-software-house
git add config.yaml .gitignore README.md
git commit -m "feat: add Ollama config, gitignore config.local.yaml, README setup guide

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Part B — copilot-software-house

Work from: `/home/wanleung/Projects/copilot-software-house`

---

### Task 4: Tests + `_deep_merge` + `_run_ollama` (copilot-software-house)

**Files:**
- Create: `tests/test_ollama.py`
- Modify: `orchestrator.py` (add `_deep_merge`)
- Modify: `agents/base_agent.py` (add `ollama_url` param, `_run_ollama`, branch in `_run`)

- [ ] **Step 1: Create `tests/test_ollama.py`**

```python
"""Unit tests for Ollama support in copilot-software-house."""
import pytest
from unittest.mock import MagicMock, patch, call
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))


# ── _deep_merge ──────────────────────────────────────────────────────────────

def test_deep_merge_non_overlapping():
    from orchestrator import _deep_merge
    result = _deep_merge({"a": 1}, {"b": 2})
    assert result == {"a": 1, "b": 2}


def test_deep_merge_override_scalar():
    from orchestrator import _deep_merge
    result = _deep_merge({"x": "old"}, {"x": "new"})
    assert result == {"x": "new"}


def test_deep_merge_nested():
    from orchestrator import _deep_merge
    base = {"llm": {"model": "claude-sonnet-4.6", "overrides": {"engineer": "gpt-4.1"}}}
    override = {"llm": {"ollama_url": "http://10.0.0.1:11434", "overrides": {"engineer": "ollama/qwen2.5-coder"}}}
    result = _deep_merge(base, override)
    assert result["llm"]["model"] == "claude-sonnet-4.6"
    assert result["llm"]["ollama_url"] == "http://10.0.0.1:11434"
    assert result["llm"]["overrides"]["engineer"] == "ollama/qwen2.5-coder"


def test_deep_merge_does_not_mutate():
    from orchestrator import _deep_merge
    base = {"a": {"b": 1}}
    _deep_merge(base, {"a": {"c": 2}})
    assert base == {"a": {"b": 1}}


# ── _run routing ─────────────────────────────────────────────────────────────

def test_run_routes_ollama_model_to_run_ollama():
    """When model starts with 'ollama/', _run() calls _run_ollama, not subprocess."""
    from agents.base_agent import BaseAgent
    agent = BaseAgent(model="ollama/llama3.2", ollama_url="http://localhost:11434")
    with patch.object(agent, "_run_ollama", return_value="response") as mock_ollama, \
         patch.object(agent, "_run_subprocess") as mock_sub:
        result = agent._run("hello", max_retries=0, timeout=30)
    mock_ollama.assert_called_once_with("hello", max_retries=0, timeout=30)
    mock_sub.assert_not_called()
    assert result == "response"


def test_run_routes_normal_model_to_subprocess():
    """Non-ollama models go through the subprocess path."""
    from agents.base_agent import BaseAgent
    agent = BaseAgent(model="claude-sonnet-4.6")
    with patch.object(agent, "_run_subprocess", return_value="sub response") as mock_sub, \
         patch.object(agent, "_run_ollama") as mock_ollama:
        result = agent._run("hello", max_retries=0, timeout=30)
    mock_sub.assert_called_once()
    mock_ollama.assert_not_called()
    assert result == "sub response"


# ── _run_ollama ───────────────────────────────────────────────────────────────

def test_run_ollama_strips_prefix_and_calls_api():
    """_run_ollama strips 'ollama/' prefix and calls OpenAI-compatible API."""
    from agents.base_agent import BaseAgent
    agent = BaseAgent(model="ollama/qwen2.5-coder", ollama_url="http://10.0.0.1:11434")
    agent.system_prompt = "You are a coder."

    mock_response = MagicMock()
    mock_response.choices[0].message.content = "def hello(): pass"

    with patch("agents.base_agent.OpenAI") as mock_cls:
        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_cls.return_value = mock_client

        result = agent._run_ollama("write hello", max_retries=0, timeout=60)

    mock_cls.assert_called_once_with(base_url="http://10.0.0.1:11434/v1", api_key="ollama")
    mock_client.chat.completions.create.assert_called_once_with(
        model="qwen2.5-coder",
        messages=[
            {"role": "system", "content": "You are a coder."},
            {"role": "user", "content": "write hello"},
        ],
        temperature=0.3,
        timeout=60,
    )
    assert result == "def hello(): pass"


def test_run_ollama_omits_system_message_when_empty():
    """If system_prompt is empty, no system message is sent."""
    from agents.base_agent import BaseAgent
    agent = BaseAgent(model="ollama/llama3.2", ollama_url="http://localhost:11434")
    agent.system_prompt = ""

    mock_response = MagicMock()
    mock_response.choices[0].message.content = "hi"

    with patch("agents.base_agent.OpenAI") as mock_cls:
        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = mock_response
        mock_cls.return_value = mock_client

        agent._run_ollama("hello", max_retries=0, timeout=30)

    args = mock_client.chat.completions.create.call_args
    messages = args.kwargs["messages"]
    roles = [m["role"] for m in messages]
    assert "system" not in roles
```

- [ ] **Step 2: Run tests — expect failures**

```bash
cd /home/wanleung/Projects/copilot-software-house && python -m pytest tests/test_ollama.py -v 2>&1 | tail -20
```

Expected: `ImportError` for `_deep_merge`, `_run_ollama`, `_run_subprocess` not yet defined.

- [ ] **Step 3: Add `_deep_merge` to `orchestrator.py`**

Add after the import block, before the `Orchestrator` class definition:

```python
def _deep_merge(base: dict, override: dict) -> dict:
    """Recursively merge override into base, returning a new dict.

    Nested dicts are merged at the leaf level; scalars are overwritten.
    Neither input dict is mutated.
    """
    result = dict(base)
    for key, val in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(val, dict):
            result[key] = _deep_merge(result[key], val)
        else:
            result[key] = val
    return result
```

- [ ] **Step 4: Refactor `BaseAgent._run` into `_run_subprocess` and add `_run_ollama`**

In `agents/base_agent.py`:

1. Rename the existing `_run` method to `_run_subprocess` (keep the body identical).

2. Add a new `_run` method that dispatches:

```python
    def _run(self, prompt: str, *, max_retries: int, timeout: int) -> str:
        """Dispatch to Ollama or Copilot subprocess based on model prefix."""
        if self.model.startswith("ollama/"):
            return self._run_ollama(prompt, max_retries=max_retries, timeout=timeout)
        return self._run_subprocess(prompt, max_retries=max_retries, timeout=timeout)
```

3. Add `_run_ollama` method:

```python
    def _run_ollama(self, prompt: str, *, max_retries: int, timeout: int) -> str:
        """Call an Ollama model via its OpenAI-compatible API."""
        from openai import OpenAI
        bare_model = self.model.removeprefix("ollama/")
        client = OpenAI(base_url=f"{self.ollama_url}/v1", api_key="ollama")

        messages: list[dict] = []
        if self.system_prompt:
            messages.append({"role": "system", "content": self.system_prompt})
        messages.append({"role": "user", "content": prompt})

        for attempt in range(max_retries + 1):
            try:
                response = client.chat.completions.create(
                    model=bare_model,
                    messages=messages,
                    temperature=0.3,
                    timeout=timeout,
                )
                return response.choices[0].message.content or ""
            except Exception as exc:
                logger.warning("Ollama attempt %d/%d failed: %s", attempt + 1, max_retries + 1, exc)
                if attempt == max_retries:
                    raise RuntimeError(
                        f"Ollama model '{bare_model}' failed after {max_retries + 1} attempt(s). "
                        f"Is the Ollama server at {self.ollama_url} running? "
                        f"Pull the model with: ollama pull {bare_model}"
                    ) from exc
                time.sleep(2 ** attempt)

        raise RuntimeError("All Ollama retries exhausted")  # unreachable, satisfies type checkers
```

4. Add `ollama_url: str = "http://localhost:11434"` to `BaseAgent.__init__` signature and store it:

```python
    def __init__(self, model: str = "claude-sonnet-4.6", role_file: str | None = None, timeout: int = 600, ollama_url: str = "http://localhost:11434"):
        self.model = model
        self.timeout = timeout
        self.ollama_url = ollama_url
        self.system_prompt = ""
        if role_file:
            path = Path(role_file)
            if path.exists():
                self.system_prompt = path.read_text().strip()
        self._history: list[dict[str, str]] = []
        self.memory_prefix: str = ""
        self.cwd: Path | None = None
```

- [ ] **Step 5: Run tests — expect all pass**

```bash
cd /home/wanleung/Projects/copilot-software-house && python -m pytest tests/test_ollama.py -v
```

Expected: all PASS.

- [ ] **Step 6: Run existing tests to verify no regression**

```bash
cd /home/wanleung/Projects/copilot-software-house && python -m pytest tests/test_readme.py -v
```

Expected: PASS (README test still works).

- [ ] **Step 7: Commit**

```bash
cd /home/wanleung/Projects/copilot-software-house
git add tests/test_ollama.py agents/base_agent.py orchestrator.py
git commit -m "feat: add Ollama backend to BaseAgent and _deep_merge helper

- BaseAgent: ollama_url param, _run_ollama(), _run() dispatch
- _run_subprocess(): existing subprocess logic (renamed from _run)
- _deep_merge(): recursive config merge for config.local.yaml support

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: Wire Ollama config loading in copilot-software-house Orchestrator

**Files:**
- Modify: `orchestrator.py` (`Orchestrator.__init__`)

- [ ] **Step 1: Load `config.local.yaml` in `Orchestrator.__init__`**

Find the `__init__` method. After the `self.cfg = yaml.safe_load(f)` line, add:

```python
        # Layer config.local.yaml (gitignored) on top for local overrides
        local_path = Path(config_path).parent / "config.local.yaml"
        if local_path.exists():
            with open(local_path, encoding="utf-8") as lf:
                local_cfg = yaml.safe_load(lf) or {}
            self.cfg = _deep_merge(self.cfg, local_cfg)
```

(Requires `from pathlib import Path` — check it's already imported; it is.)

- [ ] **Step 2: Extract `ollama_url` from config**

Find where `self.default_model` is set (right after config loading). Add:

```python
        self.ollama_url: str = self.cfg.get("llm", {}).get("ollama_url", "http://localhost:11434")
```

- [ ] **Step 3: Set `ollama_url` on all constructed agents**

Find the agent factory methods (`_make_product_manager`, direct construction, etc.). The cleanest approach for copilot-software-house (where subclasses override `__init__` without `ollama_url`) is to set the attribute after construction.

Add a helper at the top of the Orchestrator class body:

```python
    def _wire_agent(self, agent):
        """Set shared runtime config on an agent after construction."""
        agent.ollama_url = self.ollama_url
        return agent
```

Then wrap every agent construction call with `self._wire_agent(...)`. For example, find:

```python
pm = ProductManagerAgent(model=self._model("product_manager"), timeout=self._timeout("product_manager"))
```

And change to:

```python
pm = self._wire_agent(ProductManagerAgent(model=self._model("product_manager"), timeout=self._timeout("product_manager")))
```

Do this for every agent construction in `orchestrator.py` (ProductManagerAgent, ArchitectAgent, EngineerAgent, QAEngineerAgent, CodeReviewerAgent, QAPlannerAgent, DeploymentTesterAgent, MemoryBankUpdaterAgent, SummaryAgent, MemoryConsolidatorAgent, RefactorAgent).

- [ ] **Step 4: Verify orchestrator imports cleanly**

```bash
cd /home/wanleung/Projects/copilot-software-house && python -c "from orchestrator import Orchestrator, _deep_merge; print('OK')"
```

Expected: `OK`

- [ ] **Step 5: Run full test suite**

```bash
cd /home/wanleung/Projects/copilot-software-house && python -m pytest tests/ -v
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
cd /home/wanleung/Projects/copilot-software-house
git add orchestrator.py
git commit -m "feat: load config.local.yaml and wire ollama_url to all agents

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 6: Config, gitignore, requirements, README for copilot-software-house

**Files:**
- Modify: `config.yaml`
- Modify: `.gitignore`
- Modify: `requirements.txt`
- Modify: `README.md`

- [ ] **Step 1: Add `ollama_url` and Ollama examples to `config.yaml`**

Find the `llm:` section and add after the existing model comment block:

```yaml
  # ── Ollama (local — no API key or Copilot subscription required) ───────
  #   ollama/llama3.2              (general purpose)
  #   ollama/qwen2.5-coder         (code-focused, recommended for engineer)
  #   ollama/mistral               (fast, lightweight)
  #
  # Ollama models are auto-detected by the "ollama/" prefix.
  # No GITHUB_TOKEN or Copilot subscription needed for Ollama models.

  # Ollama server URL. Override in config.local.yaml for non-default hosts.
  # config.local.yaml is gitignored — safe for private network addresses.
  ollama_url: "http://localhost:11434"
```

- [ ] **Step 2: Add `config.local.yaml` to `.gitignore`**

Open `.gitignore` and add:

```
config.local.yaml
```

- [ ] **Step 3: Add `openai` to `requirements.txt`**

Open `requirements.txt` and add:

```
openai>=1.0
```

Install it in the venv:

```bash
cd /home/wanleung/Projects/copilot-software-house && source venv/bin/activate && pip install openai>=1.0 --quiet
```

Expected: installs or already satisfied.

- [ ] **Step 4: Add Ollama section to `README.md`**

Find the `## Configuration` section (or appropriate location) and add:

```markdown
## Ollama (Local Models)

Run agents entirely locally — no Copilot subscription, no API keys, no cloud costs.

### Prerequisites

1. Install Ollama: <https://ollama.com>
2. Pull a model:
   ```bash
   ollama pull llama3.2          # general purpose
   ollama pull qwen2.5-coder     # recommended for engineer role
   ```
3. The Ollama server starts automatically after install (or run `ollama serve`).

### Configuration

Set models with the `ollama/` prefix in `config.yaml`:

```yaml
llm:
  model: "ollama/llama3.2"        # use Ollama for all agents
  overrides:
    engineer: "ollama/qwen2.5-coder"   # code-focused model for engineer
```

To use a non-default Ollama server (e.g. on your local network), create
`config.local.yaml` — it is gitignored and never committed:

```yaml
# config.local.yaml — gitignored, never committed
llm:
  ollama_url: "http://10.100.1.30:11434"
  overrides:
    engineer: "ollama/qwen2.5-coder"
```

Mix Ollama with Copilot-subscription models freely — each agent can use a different backend:

```yaml
llm:
  model: "claude-sonnet-4.6"           # default: Copilot subscription
  overrides:
    engineer: "ollama/qwen2.5-coder"   # engineer: local Ollama
```
```

- [ ] **Step 5: Run full test suite to confirm no regressions**

```bash
cd /home/wanleung/Projects/copilot-software-house && python -m pytest tests/ -v
```

Expected: all PASS.

- [ ] **Step 6: Commit and push both repos**

```bash
cd /home/wanleung/Projects/copilot-software-house
git add config.yaml .gitignore requirements.txt README.md
git commit -m "feat: Ollama config, gitignore, requirements, README setup guide

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin master

cd /home/wanleung/Projects/ai-software-house
git push origin master
```

Expected: both pushes succeed.
