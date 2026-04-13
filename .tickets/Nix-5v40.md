---
id: Nix-5v40
status: open
deps: []
links: []
created: 2026-04-13T00:13:34Z
type: chore
priority: 3
assignee: Otto Ahoniemi
---

# Keep pi agent skills up-to-date with upstream tools

Several skills in ~/.pi/agent/skills/ are derived from or rely on external tools (ast-grep, tk ticket system, lat.md CLI, etc.). These skills drift from their upstream sources as the tools evolve, get new features, or change APIs.

Specifically:

- ast-grep: skill documents ast-grep rule syntax and patterns; upstream ast-grep may add/change rule features
- ticket-creator / ticket-worker / task-pipeline: these encode tk CLI conventions; if tk changes commands or flags, skills become stale
- lat-md: documents the lat.md CLI; if lat adds/changes subcommands, the skill drifts
- git-commit / git-worktrees: encode git conventions that are fairly stable but worth auditing periodically

Process: periodically (e.g. quarterly or when a tool updates), diff each skill against current upstream docs. Update skill content where it diverges. Add any new features/flags the skill should cover.

## Acceptance Criteria

1. Audit all 9 skills in ~/.pi/agent/skills/ and note which reference external tools
2. For each external-tool skill, verify skill content matches current upstream documentation
3. Update any skill content that has drifted from upstream
4. Document a repeatable review process (e.g. checklist or script) in the ticket or a plan file
