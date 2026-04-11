---
id: pshs-bwaw
status: closed
deps: []
links: []
created: 2026-04-10T13:51:10Z
type: feature
priority: 2
assignee: Otto Ahoniemi
parent: pshs-erua
tags: [ready-for-development]
---

# Create session index builder script

Create `home/configs/pi-coding-agent/scripts/build-session-index.sh` that builds `~/.cache/pi-session-index.json` from pi session JSONL files.

The script:

1. Finds all session files under `~/.pi/agent/sessions/`
2. For each file with user messages, extracts:
   - `date` from filename timestamp
   - `project` from directory name (between `--` delimiters)
   - `title` = first user message, truncated to 200 chars
   - `content` = concatenated user messages + assistant text blocks + compaction summaries, truncated to 3000 chars. Skip tool results, thinking blocks, toolCall blocks.
   - `path` = full file path
3. Outputs JSON: `{version:2, built:"ISO timestamp", entries:[...]}`
4. Skips rebuild if no session files are newer than the index (staleness check)

Implementation approach:

- Use `rg -l '"role":"user"'` to prefilter files (~4.5K of 10K)
- Extract content per file with `jq`, parallelized with `xargs -P 4`
- Target: under 30s for full rebuild of ~5K entries

Session JSONL schema for extraction:

- User messages: `select(.type=="message" and .message.role=="user") | .message.content | if type == "array" then .[] | select(.type=="text") | .text else . end`
- Assistant text: same but `.message.role=="assistant"`, only `.type=="text"` blocks (skip thinking, toolCall)
- Compaction: `select(.type=="compaction") | .summary`

See `home/configs/pi-coding-agent/extensions/firecrawl.ts` for extension conventions.
See `plans/pi-session-history-search-implementation.md` Part 1 for full spec.

## Acceptance Criteria

1. Script runs successfully: `bash home/configs/pi-coding-agent/scripts/build-session-index.sh`
2. Output file exists: `~/.cache/pi-session-index.json`
3. Index has ~4500-5100 entries: `jq '.entries | length' ~/.cache/pi-session-index.json`
4. Each entry has all required fields: date, project, title, content, path
5. Content field contains user messages, assistant text, and compaction summaries (not tool results or thinking blocks)
6. Title is first user message truncated to 200 chars
7. Content is truncated to 3000 chars per session
8. Staleness check works: running twice without new sessions skips rebuild
9. Full rebuild completes in under 30 seconds

## Notes

**2026-04-11T01:11:43Z**

Built build-session-index.sh with rg prefilter + single jq pass per file + xargs parallelism (8 workers). Builds index of 4494 entries in ~19s. Staleness check skips rebuild when index is newer than all session files.
