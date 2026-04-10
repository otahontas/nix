---
id: Nix-4ua7
status: closed
deps: [Nix-f4x8]
links: []
created: 2026-04-10T08:25:22Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add verification pass to work-tickets.sh after ticket closure

Modify work-tickets.sh to run a verification pass after a ticket is closed by the agent. This enforces programmatic verification instead of relying on skill instructions alone.

Problem: ForgeCode found that prompting 'please verify' did not work — only enforcement did (Phase 2). Currently work-tickets.sh checks ticket status after each pi -p attempt but never verifies the changes are actually correct.

Changes to home/configs/pi-coding-agent/scripts/work-tickets.sh:

1. After a ticket is closed (status = closed), run a second pi -p call with a verification prompt
2. The verification prompt must be specific — tell the agent exactly what to do:
   - tk show TICKET to re-read acceptance criteria
   - git diff HEAD~1 to see what changed
   - Run project test/lint commands
   - Check for common issues (unused imports, debug prints, TODO comments)
3. If verification finds issues: the agent runs tk reopen TICKET and tk add-note TICKET with failure details
4. If verification passes: ticket stays closed
5. After verification, re-check ticket status to determine final outcome
6. The retry loop continues if the ticket was reopened during verification
7. Verification only runs once per closure (not retried independently)

The verification prompt template should use a variable like VERIFY_PROMPT similar to the existing work prompt pattern.

## Acceptance Criteria

1. work-tickets.sh runs a second pi -p call after detecting ticket status = closed
2. The verification prompt includes specific instructions: tk show, git diff HEAD~1, run tests/linter, check for debug code
3. If verification agent finds issues, it runs tk reopen on the ticket
4. If verification passes, ticket remains closed and script prints a verified confirmation message
5. After verification, script re-checks ticket status and counts correctly (COMPLETED only if still closed)
6. If ticket is reopened during verification, the retry loop continues with another work attempt
7. Verification runs at most once per closure attempt (not independently retried)
8. The --help or header output mentions the verification step so users know it exists
9. Existing behavior (TAG, MAX_RETRIES, retry loop) is preserved

## Notes

**2026-04-10T08:45:44Z**

Added verification pass to work-tickets.sh. After a ticket is closed, a second pi -p call runs with a specific verification prompt (tk show, git diff HEAD~1, test/lint, debug code check). If verification fails, the agent reopens the ticket and the retry loop continues. Verification runs once per closure attempt. Header output now shows 'verification: on'.
