---
id: Nix-nnbg
status: open
deps: [Nix-aw1p, Nix-2eoh]
links: []
created: 2026-04-05T18:18:28Z
type: feature
priority: 1
assignee: Otto Ahoniemi
tags:
  - ready-for-development
---

# Update stop-hook to use local model with cloud fallback

Update the gatekeeper logic in stop-hook.ts to prefer the local model, falling back to the cloud model if the local one is unavailable.

Final flow:

1. agent_end fires
2. No tool calls → skip nudge
3. Tool calls → try local gatekeeper model first
4. If local unavailable → try cloud gatekeeper model (z.ai)
5. If both unavailable → nudge by default
6. Otherwise: respect gatekeeper yes/no decision

This ties together all previous work:

- Ticket Nix-5oy7: no-tool-call skip logic
- Ticket Nix-nt4b (or replacement): cloud model added to models.json
- Ticket Nix-2eoh: local model added to models.json
- Ticket Nix-aw1p: gatekeeper calling logic

The agent working this ticket should read stop-hook.ts (which will have cloud gatekeeper logic from Nix-aw1p) and extend it to try the local model first. Read models.json to find both the local and cloud gatekeeper model IDs.

File: ~/.pi/agent/extensions/stop-hook.ts

## Acceptance Criteria

1. `grep` stop-hook.ts for code that tries a local model provider before the cloud model
2. `grep` stop-hook.ts for fallback chain: local → cloud → default-nudge
3. Code has try/catch around local model call: on failure, falls through to cloud model
4. Code has try/catch around cloud model call: on failure, sends nudge as safe default
5. `pi -e ~/.pi/agent/extensions/stop-hook.ts` starts without errors
6. Add a note to this ticket describing the full fallback chain implemented
