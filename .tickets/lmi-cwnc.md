---
id: lmi-cwnc
status: closed
deps: [lmi-w2zq]
links: []
created: 2026-04-11T09:28:52Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Update ticket-worker skill for lat.md awareness

When lat.md/ exists in a project, ticket-worker should use lat search for exploration and enforce lat check during verification.

Changes to ticket-worker SKILL.md:

1. Step 2 (Explore the codebase): add as first action — if lat.md/ exists, run lat search with keywords from ticket title/description, then lat section for relevant matches
2. Step 5 (Verify acceptance criteria): add — if lat.md/ exists, run lat check. If it fails, update lat.md/ to reflect changes and re-run until it passes
3. Step 6 (Commit and close): add note — if lat.md/ was updated, include those changes in the commit

Rationale: this creates the enforcement chain — the agent cannot close a ticket without keeping the knowledge graph in sync.

Files:

- home/configs/pi-coding-agent/skills/ticket-worker/SKILL.md

## Acceptance Criteria

1. Step 2 has lat search instruction when lat.md/ exists
2. Step 5 has lat check enforcement when lat.md/ exists
3. Step 6 mentions committing lat.md/ changes
4. Existing behavior unchanged for repos without lat.md/
5. Skill reads cleanly — conditional instructions, not duplicated
