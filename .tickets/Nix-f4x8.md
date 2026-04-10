---
id: Nix-f4x8
status: closed
deps: []
links: []
created: 2026-04-10T08:24:32Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add non-interactive mode extension for pi -p sessions

Create a new extension that detects when pi is running in non-interactive mode (pi -p, pi -c) and injects system prompt instructions that prevent conversational behavior.

Problem: When work-tickets.sh runs pi -p for each ticket, the agent can ask clarifying questions, produce conversational filler, and wait for input that never comes. ForgeCode found that a non-interactive runtime profile was their single biggest stabilization fix (Phase 1 benchmarks).

How it works:

- Subscribe to before_agent_start event
- When ctx.hasUI is false (print mode, no TUI), append non-interactive instructions to the system prompt
- When ctx.hasUI is true (interactive mode), do nothing
- Instructions should tell the agent: never ask questions, make assumptions, minimize chatter, document blockers and stop if stuck

File to create: home/configs/pi-coding-agent/extensions/non-interactive.ts
The extension follows the same pattern as existing extensions (guardrails.ts, stop-hook.ts, notify.ts).
Auto-discovered by default.nix via extensionFiles logic — no nix changes needed.

## Acceptance Criteria

1. File home/configs/pi-coding-agent/extensions/non-interactive.ts exists and follows existing extension patterns (export default function(pi: ExtensionAPI))
2. Extension subscribes to before_agent_start event
3. When ctx.hasUI is false, system prompt is appended with non-interactive instructions (no questions, make assumptions, document blockers)
4. When ctx.hasUI is true, system prompt is not modified
5. File is staged in git (new file, needed for home-manager auto-discovery)
6. pi -p 'List files in the current directory' produces output without conversational filler (no 'Would you like me to...', no 'I'll wait for your input')
7. Interactive pi sessions are unaffected (no extra prompt text injected)

## Notes

**2026-04-10T08:40:18Z**

Created non-interactive.ts extension. Subscribes to before_agent_start, checks ctx.hasUI, and appends non-interactive instructions to system prompt when no TUI is present. Auto-discovered by default.nix. All 7 acceptance criteria verified.
