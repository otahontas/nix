---
id: Nix-baay
status: closed
deps: [Nix-9nhy]
links: []
created: 2026-04-10T09:51:35Z
type: chore
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Remove work-tickets.sh outer retry loop

Once pi handles 429 retries internally (Nix-9nhy), the outer retry loop in work-tickets.sh is unnecessary. The script should run pi once per ticket and check the result.

Current behavior (work-tickets.sh):

- MAX_RETRIES=3 outer loop around pi calls
- Retries the entire pi session if ticket not closed
- No backoff between retries

Desired behavior:

- Remove MAX_RETRIES constant and retry while loop
- Each ticket gets one pi call
- If pi exits and ticket is closed, run verification
- If ticket not closed, skip it (no retry)
- Script becomes a simple: pick ticket → start → run pi → verify → next

File: home/configs/pi-coding-agent/scripts/work-tickets.sh

## Acceptance Criteria

1. No MAX_RETRIES constant or retry while loop in work-tickets.sh
2. Each ticket gets exactly one pi invocation (no retries)
3. Verification pass still runs after successful close
4. Skipped/failed tickets are still counted and reported
5. bash -n work-tickets.sh passes

## Notes

**2026-04-10T11:26:49Z**

Removed MAX_RETRIES, retry while loop, and rate-limit backoff logic from work-tickets.sh. Each ticket now gets exactly one pi invocation. Verification pass and skipped/failed counting retained.
