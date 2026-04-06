---
id: Nix-z4wp
status: closed
deps: [Nix-ra0y]
links: []
created: 2026-04-05T20:00:56Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Switch local gatekeeper model from Qwen3.5-0.8B to Gemma4 E2B

Replace the current local model (qwen3.5:0.8b) with gemma4:e2b in Ollama and models.json.

Gemma4:E2B is a strictly better choice for the gatekeeper classifier:

- 2.3B effective params (vs 0.8B) — much better reasoning for agent behavior classification
- 7.2 GB on disk — still fits easily on 16 GB M1 Pro with headroom
- Native system prompt support and function calling
- Beats Gemma 3 27B on most benchmarks despite being 12x smaller
- Same integration path: Ollama + OpenAI-compatible API, zero friction

Steps:

1. Pull the new model: ollama pull gemma4:e2b
2. Update ~/.pi/agent/models.json: change the ollama provider model from qwen3.5:0.8b to gemma4:e2b, update contextWindow to 128000
3. Verify ollama serves the model at the existing endpoint
4. Test a classification prompt through the model
5. Optionally remove old model to free disk: ollama delete qwen3.5:0.8b

Files: ~/.pi/agent/models.json
Runtime: Ollama (already configured in devenv.nix)

Note: This replaces the model installed in Nix-ra0y. The ollama provider config stays the same — only the model ID and contextWindow change.

## Acceptance Criteria

1. ollama pull gemma4:e2b completes and model appears in ollama list
2. curl http://localhost:11434/v1/chat/completions with model gemma4:e2b returns a valid response
3. ~/.pi/agent/models.json ollama provider lists gemma4:e2b with contextWindow: 128000 and no longer lists qwen3.5:0.8b
4. Response latency for a short classification prompt is under 3 seconds
5. Old model cleaned up from ollama storage (disk space freed)

## Notes

**2026-04-05T20:23:43Z**

Switched gatekeeper model from qwen3.5:0.8b to gemma4:e2b. Updated models.json (id, contextWindow 128000, maxTokens 8192). Had to override ollama package in devenv.nix to fetch 0.20.2 binary from GitHub since nixpkgs rolling only has 0.18.0 (gemma4 support requires 0.20+). Old qwen3.5:0.8b model deleted from ollama storage. Warm-cache latency ~1.5s for short classification prompts.
