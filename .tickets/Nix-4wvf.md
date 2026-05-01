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
- home/configs/pi-coding-agent/skills/task-pipeline/SKILL.md (reference for subagent usage patterns)

## Agent definition to implement

```markdown
---
name: searcher
description: Searches for information (codebase, web, docs) and writes results to a specified file. Use for parallel information retrieval via subagent tasks array.
tools: read, write, bash, web_search, code_search, fetch_content, get_search_content, grep, find, ls
---

You are a search agent. You receive a specific query, find the answer, and write results to the file specified in your task prompt.

## Constraints

- Write results only to the file path specified in the task prompt
- Forbidden bash commands: git commit, git push, pnpm add, npm install, cp, mv, trash, curl (with POST/PUT/DELETE), write redirection (>)
- Allowed bash commands: git log, git diff, git show, rg, grep, find, cat, ls, head, tail, wc, file, devenv

## Strategy

1. Read the task prompt — it contains a query and an output file path
2. Search using available tools (grep/find for code, web_search for external, fetch_content for URLs)
3. Synthesize findings into a concise, structured result
4. Write to the specified file path using the `write` tool

## Output format

# <query summary>

## Findings

- Finding 1 with sources
- Finding 2 with sources
- ...

## Sources

- file paths, URLs, line numbers

Be concise. Focus on facts relevant to the query. Include sources for verification.
```

## Acceptance Criteria

1. searcher.md exists in home/configs/pi-coding-agent/agents/ with correct frontmatter (name: searcher, description, tools list including read, write, bash, web_search, code_search, fetch_content, get_search_content, grep, find, ls)
2. Agent has constraints section with forbidden/allowed bash commands matching researcher.md conventions
3. Agent has strategy section describing query → search → synthesize → write workflow
4. Agent has output format section (heading + findings + sources)
5. File is staged and committed
6. devenv tasks run home:apply succeeds and searcher.md appears as symlink in ~/.pi/agent/agents/
7. lat.md updated if needed, lat_check passes
