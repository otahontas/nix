---
id: lmi-8btd
status: closed
deps: [lmi-w2zq]
links: []
created: 2026-04-11T09:29:15Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add lat check to work-tickets.sh verification prompt

Add lat check to the verification pass in work-tickets.sh. When lat.md/ exists in the project, the verification agent should run lat check and reopen the ticket if it fails.

Changes to scripts/work-tickets.sh:

1. Add step 5 to VERIFY_PROMPT: 'If lat.md/ exists in the project, run lat check. If it reports errors, run tk reopen TICKET and add a note with the errors.'
2. The condition is in the prompt text itself — the agent checks for lat.md/ and decides whether to run lat check. No shell-level changes needed.

The existing VERIFY_PROMPT already has 4 steps (re-read criteria, git diff, test/lint, common issues). This adds a 5th step for knowledge graph consistency.

Files:

- home/configs/pi-coding-agent/scripts/work-tickets.sh

## Acceptance Criteria

1. VERIFY_PROMPT has step 5 for lat check when lat.md/ exists
2. Step instructs agent to reopen ticket if lat check fails
3. Existing 4 verification steps unchanged
4. Repos without lat.md/ skip this step naturally (agent checks directory existence)

## Notes

**2026-04-11T10:20:51Z**

Added step 5 to VERIFY_PROMPT: checks for lat.md/ directory and runs lat check if present, reopening ticket on failure. Single line addition, existing steps 1-4 unchanged.
