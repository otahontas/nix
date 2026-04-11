---
id: pshs-erua
status: closed
deps: []
links: []
created: 2026-04-10T13:50:16Z
type: epic
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add BM25-based session history search for pi agent

Epic: implement full-text search across past pi conversations using BM25 ranking.
Searches user messages, assistant text, and compaction summaries.
Background-indexed via launchd timer, queried via pi extension tools.
See plans/pi-session-history-search-implementation.md for the full plan.

## Notes

**2026-04-11T01:22:00Z**

All child tickets completed. launchd indexer running every 2h, search-sessions.ts extension with BM25 ranking deployed. Single commit 327576a.
