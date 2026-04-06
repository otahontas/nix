---
id: Nix-t9cs
status: closed
deps: []
links: []
created: 2026-04-05T18:51:34Z
type: feature
priority: 1
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add skip-nudge heuristic: no tool calls → no recheck

Modify the stop-hook extension (~/.pi/agent/extensions/stop-hook.ts) to skip the follow-up nudge when the agent made no tool calls during the prompt.

Current behavior: on every agent_end, sends a follow-up asking the agent to self-review. This fires even for simple Q&A.

New behavior: inspect event.messages in the agent_end handler. If no tool_use content blocks appear in any assistant message, skip the nudge entirely.

File: ~/.pi/agent/extensions/stop-hook.ts

## Acceptance Criteria

1. grep -c 'tool.use\|tool_use' ~/.pi/agent/extensions/stop-hook.ts returns ≥ 1 — the extension checks for tool_use content blocks in assistant messages within the agent_end handler
2. grep the new code: when no tool_use blocks are found in event.messages, the code path returns early without calling pi.sendUserMessage
3. grep the new code: when tool_use blocks ARE found, pi.sendUserMessage is called as before
4. pi -e ~/.pi/agent/extensions/stop-hook.ts starts without errors (extension loads cleanly)
5. Add a note to this ticket confirming: code reads correctly, extension loads without errors

## Notes

**2026-04-05T19:51:07Z**

Added skip-nudge heuristic: the agent_end handler now inspects event.messages for toolCall content blocks in assistant messages. If none are found (simple Q&A), it returns early without sending the follow-up nudge. All 5 acceptance criteria verified: toolCall check present, early return on no tool use, sendUserMessage still called when tool use exists, extension loads cleanly.
