---
id: Nix-ra0y
status: open
deps: [Nix-avnx]
links: []
created: 2026-04-05T18:53:01Z
type: feature
priority: 1
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Install Ollama with Qwen3.5-0.8B and add to pi-agent models.json

Install Ollama via devenv.nix, pull the Qwen3.5-0.8B model, and register it in pi-agent's model config so it can be used as a local classifier.

## Steps

1. Add `ollama` to devenv.nix packages (or as a process/service)
2. Start ollama and pull the model: `ollama pull qwen3.5:0.8b`
3. Verify ollama serves OpenAI-compatible API at `http://localhost:11434/v1/chat/completions`
4. Add the model to `~/.pi/agent/models.json` as a new provider:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://localhost:11434/v1",
      "apiKey": "ollama",
      "api": "openai-completions",
      "models": [
        {
          "id": "qwen3.5:0.8b",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 4096
        }
      ]
    }
  }
}
```

(Merge with existing providers, don't replace them.)

5. Verify pi can select and use the model via `/model` command
6. Test a classification prompt: "Respond with YES or NO: should the agent stop working?"

Files: `devenv.nix`, `~/.pi/agent/models.json`

Runtime: Ollama (nix package: `ollama`, supports aarch64-darwin, uses MLX on Apple Silicon since v0.19)
Model: Qwen3.5-0.8B (~1-2GB quantized, fits easily on 16GB M1 Pro)
Fallback model if 0.8B is too weak: `qwen2.5:0.5b`

## Acceptance criteria

1. `ollama` is available in devenv shell (added to devenv.nix packages or services)
2. `ollama pull qwen3.5:0.8b` completes and model is listed in `ollama list`
3. `curl http://localhost:11434/v1/chat/completions -d '{"model":"qwen3.5:0.8b","messages":[{"role":"user","content":"Say hello"}]}'` returns a valid response
4. `~/.pi/agent/models.json` contains the ollama provider with qwen3.5:0.8b model
5. Model appears in pi model selector (`/model`)
6. Sending a simple classification prompt through the local model works and returns a response
7. Response latency for a short classification prompt is < 3 seconds
