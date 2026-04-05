---
id: Nix-aw1p
status: open
deps: [Nix-nt4b]
links: []
created: 2026-04-05T18:17:40Z
type: feature
priority: 1
assignee: Otto Ahoniemi
tags:
  - ready-for-development
---

# Wire gatekeeper model into stop-hook: tool calls → model check → nudge decision

Extend stop-hook.ts to call the cheap gatekeeper model when tool calls are detected.

Logic:

1. agent_end fires
2. No tool calls → skip (already implemented in ticket Nix-5oy7)
3. Tool calls found → call gatekeeper model with the last user-assistant exchange
4. Gatekeeper says YES → send the nudge follow-up
5. Gatekeeper says NO → skip nudge
6. Gatekeeper model unavailable/error → nudge by default (fallback to current behavior)

Implementation approach:

- Import completeSimple from @mariozechner/pi-ai
- Use ctx.modelRegistry.find() to resolve the gatekeeper model — search for the cheap z.ai model (check models.json for the exact provider/model ID, it will have been added by the previous ticket)
- Use ctx.modelRegistry.getApiKeyAndHeaders() for auth
- Send a classification prompt with the last user-assistant exchange as context
- Parse yes/no from the response
- If the model is not found in the registry or the API call fails/throws, fall through to sending the nudge (safe default)

Gatekeeper model: the cheap z.ai model added in the previous ticket (Nix-nt4b or its replacement). The agent should read models.json to find the exact provider and model ID.

File: ~/.pi/agent/extensions/stop-hook.ts

Reference for pi extension API: /nix/store/hjphkmqvimh2qxr2yax47wlacv6f701c-pi-coding-agent-0.64.0/lib/node_modules/@mariozechner/pi-coding-agent/docs/extensions.md

## Acceptance Criteria

1. `grep 'completeSimple\|complete' ~/.pi/agent/extensions/stop-hook.ts` shows the import from @mariozechner/pi-ai
2. `grep 'modelRegistry' ~/.pi/agent/extensions/stop-hook.ts` shows model resolution code
3. Code logic: when tool calls present → gatekeeper model called → YES sends nudge, NO skips nudge
4. Code has try/catch around the gatekeeper call: on error/missing model → nudge is sent as fallback
5. `pi -e ~/.pi/agent/extensions/stop-hook.ts` starts without errors (extension loads cleanly)
6. Add a note to this ticket describing how the gatekeeper integration works
