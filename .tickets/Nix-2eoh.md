---
id: Nix-2eoh
status: open
deps: [Nix-435t]
links: []
created: 2026-04-05T18:18:09Z
type: feature
priority: 1
assignee: Otto Ahoniemi
---

# Setup local model in pi-agent and verify it works

Based on the recommendation from ticket Nix-435t, install the chosen runtime and model, add it to pi-agent's model registry, and verify it works end-to-end.

Steps:

1. Install the chosen runtime (ollama/llama.cpp/mlx) via nix if possible
2. Pull/download the recommended model
3. Add the model to ~/.pi/agent/models.json as a new provider (e.g., 'local' or 'ollama')
4. Verify: start pi, select the local model, send a test prompt
5. Check pi logs and TUI for any errors

File: ~/.pi/agent/models.json, potentially devenv.nix for runtime installation

## Acceptance Criteria

1. Local model runtime installed and model downloaded
2. Model added to models.json
3. Model appears in pi model selector (/model)
4. Sending a simple prompt through the local model works
5. No errors in pi logs or TUI output
6. Response latency is acceptable (< 3s for classification prompt)
