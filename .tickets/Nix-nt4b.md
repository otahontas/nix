---
id: Nix-nt4b
status: open
deps: [Nix-o8su]
links: []
created: 2026-04-05T18:17:21Z
type: feature
priority: 1
assignee: Otto Ahoniemi
---

# Add investigated z.ai gatekeeper model to pi-agent models.json

Add the cheap z.ai model found in the investigation ticket (Nix-o8su) to pi-agent's model registry.

This ticket should be created BY the agent working on Nix-o8su with all the specifics filled in.

General approach:

- Add model entry to ~/.pi/agent/models.json under the existing zai provider
- Verify it appears in pi's model list
- Verify a simple prompt works through pi (no errors in logs or TUI)

File: ~/.pi/agent/models.json

## Acceptance Criteria

1. Model added to models.json under zai provider
2. Model appears in pi model selector (/model)
3. Sending a simple prompt via the model works without errors
4. No error messages in pi logs
