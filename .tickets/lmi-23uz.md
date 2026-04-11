---
id: lmi-23uz
status: closed
deps: [lmi-w2zq]
links: []
created: 2026-04-11T09:28:28Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Update ticket-creator skill for lat.md awareness

When lat.md/ exists in a project, ticket-creator should skip static context seeding (plans/.ticket-context.md) and instead instruct agents to use lat search for context discovery.

Changes to ticket-creator SKILL.md:

1. In 'Context seeding' section: add a prerequisite — if lat.md/ directory exists at project root, skip plans/.ticket-context.md creation entirely
2. In Mode 2 (decompose) step 2: add instruction to run lat search with goal description when lat.md/ exists
3. In Mode 3 (seed from plan) step 2: same addition

Rationale: lat search provides living, queryable context that never goes stale. The static context file becomes redundant for repos that have a knowledge graph.

Files:

- home/configs/pi-coding-agent/skills/ticket-creator/SKILL.md

## Acceptance Criteria

1. Context seeding section has prerequisite check: skip if lat.md/ exists
2. Mode 2 step 2 mentions running lat search when lat.md/ exists
3. Mode 3 step 2 mentions running lat search when lat.md/ exists
4. Existing behavior unchanged for repos without lat.md/ (static context seeding still works)
5. Skill reads cleanly — instructions are conditional, not duplicated

## Notes

**2026-04-11T10:11:35Z**

Added lat.md/ awareness in three places: (1) Context seeding section now has a prerequisite to skip static seeding when lat.md/ exists, (2) Mode 2 step 2 runs lat search, (3) Mode 3 step 2 runs lat search. All changes are conditional — repos without lat.md/ are unaffected.
