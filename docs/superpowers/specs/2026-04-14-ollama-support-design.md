# Ollama Support — Design Spec

**Date:** 2026-04-14
**Status:** Approved
**Scope:** `ai-software-house` and `copilot-software-house`

---

## Problem

Both software house systems are tied to cloud LLM providers (GitHub Models, Anthropic, GitHub
Copilot subscription). Users cannot run agents locally, incur cloud costs on every pipeline run,
and must send prompts and generated code to third-party APIs.

---

## Solution

Add Ollama as a first-class backend in both repos. Users specify Ollama models via an `ollama/`
prefix in model names (e.g. `ollama/llama3.2`, `ollama/qwen2.5-coder`). The Ollama server URL
is configured in a gitignored `config.local.yaml` so private network addresses are never
committed.

---

## Config Pattern (both repos)

### `config.yaml` (committed)

Add `llm.ollama_url` with a default pointing to localhost. Document Ollama model examples
alongside existing GitHub Models and Anthropic examples.

```yaml
llm:
  model: "openai/gpt-4.1"   # or "ollama/llama3.2" for fully local runs

  # Ollama server URL — override in config.local.yaml for non-default hosts
  ollama_url: "http://localhost:11434"

  overrides:
    engineer: "ollama/qwen2.5-coder"   # example: use local model for one role
```

### `config.local.yaml` (gitignored — never committed)

Deep-merged over `config.yaml` at startup. Users put private network addresses and secrets here.

```yaml
# config.local.yaml — gitignored, not committed
llm:
  ollama_url: "http://10.100.1.30:11434"
  overrides:
    engineer: "ollama/qwen2.5-coder"
```

### `.gitignore` additions (both repos)

```
config.local.yaml
```

### Config loading (both orchestrators)

Load `config.yaml`, then deep-merge `config.local.yaml` if it exists. The merge is recursive
so nested keys (e.g. `llm.overrides`) are merged at the leaf level, not replaced wholesale.

A helper `_deep_merge(base, override)` handles this — small, testable, no dependencies.

---

## ai-software-house: Third Backend

### Detection

Auto-detect backend from model name:

| Model prefix / value | Backend selected |
| --- | --- |
| `claude-*` | `anthropic` |
| `ollama/*` | `ollama` |
| anything else | `github_models` |

Explicit `backend:` parameter overrides auto-detection (existing behaviour preserved).

### `BaseAgent` changes (`agents/base_agent.py`)

1. Add `_is_ollama_model(model)` — returns `True` if model starts with `ollama/`.
2. In `__init__`: detect `ollama` backend → initialise an OpenAI SDK client with:
   - `base_url=f"{ollama_url}/v1"`
   - `api_key="ollama"` (placeholder — Ollama ignores auth but SDK requires a non-empty key)
3. Strip `ollama/` prefix before passing the model name to the API call.
4. `__init__` gains `ollama_url: str = "http://localhost:11434"` parameter.
5. The existing `github_models` call path (OpenAI SDK + retry logic) is reused as-is for Ollama
   since both use the same OpenAI-compatible interface. No separate call method needed.

### Orchestrator changes (`orchestrator.py`)

1. Load `config.local.yaml` and deep-merge into config dict after loading `config.yaml`.
2. Extract `ollama_url = config["llm"].get("ollama_url", "http://localhost:11434")`.
3. Pass `ollama_url` when constructing each `BaseAgent` subclass.
4. Update constructor signature of `BaseAgent` and every subclass accordingly.

### No new dependencies

Ollama uses the same OpenAI SDK already imported for GitHub Models. `pip install` not needed.

---

## copilot-software-house: Parallel Call Path

### Architecture

`copilot-software-house` normally shells out to `copilot --yolo -p`. For Ollama models, the
agent bypasses the subprocess and calls Ollama directly via the OpenAI SDK.

```
call(user_message)
  → _build_prompt()
  → _run(prompt)
      ├── model starts with "ollama/"  → _run_ollama(model, prompt)
      └── otherwise                   → _run_copilot(prompt)   [existing subprocess]
```

### `BaseAgent` changes (`agents/base_agent.py`)

1. `__init__` gains `ollama_url: str = "http://localhost:11434"` parameter; stored as
   `self.ollama_url`.
2. `_run()` branches on `self.model.startswith("ollama/")`:
   - True → `_run_ollama(prompt, timeout=timeout)`
   - False → existing subprocess logic (no change)
3. New `_run_ollama(prompt, timeout)`:
   - Strips `ollama/` prefix from model name.
   - Constructs messages: `[{"role": "system", "content": self.system_prompt}, {"role": "user", "content": prompt}]`
   - Uses OpenAI SDK: `OpenAI(base_url=f"{self.ollama_url}/v1", api_key="ollama")`
   - Calls `client.chat.completions.create(model=bare_model, messages=messages, temperature=0.3, timeout=timeout)`
   - Applies same retry/timeout logic as `_run()`.
   - Returns response text string.

### Orchestrator changes (`orchestrator.py`)

1. Load `config.local.yaml` and deep-merge after loading `config.yaml`.
2. Extract `ollama_url` from merged config.
3. Pass `ollama_url` to `BaseAgent.__init__` for every agent constructed.

### Dependency

The OpenAI SDK (`openai` package) is added to `requirements.txt`. It is a small, widely-used
package and has no conflict with the existing stack.

---

## Error Handling

| Scenario | Behaviour |
| --- | --- |
| Ollama server not reachable | `ConnectionError` raised; orchestrator surfaces it with message "Ollama server at {url} is not reachable. Is it running?" |
| Model not pulled on Ollama | Ollama returns 404; agent raises `RuntimeError` with model name and pull hint |
| `config.local.yaml` missing | Silently skipped; defaults from `config.yaml` are used |
| `config.local.yaml` malformed | `yaml.YAMLError` raised on startup with clear message |

---

## Out of Scope

- Streaming responses (both repos use blocking calls; Ollama streaming not needed)
- Ollama model pull automation (user pulls models manually with `ollama pull <model>`)
- Auth/API key support for Ollama (Ollama is unauthenticated by design)
- Changes to the watcher or GitHub Actions workflows

---

## File Changes Summary

### ai-software-house

| File | Change |
| --- | --- |
| `agents/base_agent.py` | Add `ollama` backend detection, `ollama_url` param, reuse OpenAI client path |
| `orchestrator.py` | Load `config.local.yaml`, extract `ollama_url`, pass to agents |
| `config.yaml` | Add `ollama_url`, document Ollama model examples |
| `.gitignore` | Add `config.local.yaml` |
| `README.md` | Add Ollama setup section |

### copilot-software-house

| File | Change |
| --- | --- |
| `agents/base_agent.py` | Add `ollama_url` param, `_run_ollama()` method, branch in `_run()` |
| `orchestrator.py` | Load `config.local.yaml`, extract `ollama_url`, pass to agents |
| `config.yaml` | Add `ollama_url`, document Ollama model examples |
| `.gitignore` | Add `config.local.yaml` |
| `requirements.txt` | Add `openai` |
| `README.md` | Add Ollama setup section |
