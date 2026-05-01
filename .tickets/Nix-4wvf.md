---
id: Nix-4wvf
status: open
deps: []
links: []
created: 2026-05-01T13:50:14Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add generic searcher subagent for parallel information retrieval

Create a new subagent at home/configs/pi-coding-agent/agents/searcher.md — a generic, parallel-friendly agent for ad-hoc information retrieval that writes results to an arbitrary file path.

Context: the existing researcher agent is tightly scoped to codebase research and writes only to plans/task.md via the write-task tool. A searcher agent fills a different role: lightweight, parallelizable queries (web, codebase, docs, URLs) with output to any file specified in the task prompt. Designed for use via subagent({tasks: [{agent: 'searcher', task: '...'}]}) for parallel batch searches.

Key files:

- home/configs/pi-coding-agent/agents/searcher.md (create)
- home/configs/pi-coding-agent/agents/researcher.md (reference for conventions)
- home/configs/pi-coding-agent/agents/planner.md (reference for conventions)
- Research: plans/task.md

## Acceptance Criteria

1. searcher.md exists in home/configs/pi-coding-agent/agents/ with correct frontmatter (name: searcher, description, tools list including read, write, bash, web_search, code_search, fetch_content, get_search_content, grep, find, ls)
2. Agent has constraints section with forbidden/allowed bash commands matching researcher.md conventions
3. Agent has strategy section describing query → search → synthesize → write workflow
4. Agent has output format section (heading + findings + sources)
5. File is staged and committed
6. devenv tasks run home:apply succeeds and searcher.md appears as symlink in ~/.pi/agent/agents/
7. lat.md updated if needed, lat_check passes
