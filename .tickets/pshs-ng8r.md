---
id: pshs-ng8r
status: closed
deps: [pshs-bwaw]
links: []
created: 2026-04-10T13:51:58Z
type: feature
priority: 2
assignee: Otto Ahoniemi
parent: pshs-erua
tags: [ready-for-development]
---

# Create search-sessions pi extension with BM25 ranking

Create `home/configs/pi-coding-agent/extensions/search-sessions.ts` — a pi extension with two tools and inline BM25 scoring.

**Tool 1: `search_sessions`**
Parameters: query (string, required), project (string, optional), days (number, optional)

- Reads index from `~/.cache/pi-session-index.json` on first call, caches in memory
- If index missing, returns error message
- Tokenizes query, scores each session with BM25 across `title` (3x boost) and `content` (1x)
- Applies project/date filters
- Returns top 10 results: date, project, title (truncated), path

**Tool 2: `read_session`**
Parameters: path (string, required), max_messages (number, optional, default 20)

- Reads the JSONL file at the given path
- Extracts user + assistant text pairs (skip tool calls/results/thinking)
- Returns condensed conversation with session header (cwd, date)

**BM25 implementation** (~50 lines inline, no npm deps):

```
For each query term t:
  IDF(t) = log((N - df(t) + 0.5) / (df(t) + 0.5))
  For each field (title, content):
    fieldScore = IDF × (tf × (k1+1)) / (tf + k1 × (1-b + b×docLen/avgLen))
  totalScore += titleScore × 3.0 + contentScore × 1.0
```

Parameters: k1=1.2, b=0.75. Tokenization: `text.toLowerCase().split(/\W+/).filter(t => t.length > 1)`

**Prompt integration:**

- promptSnippet: `"Search past pi conversations with search_sessions."`
- promptGuidelines: `"When the user references past conversations ('we discussed X', 'remember when'), use search_sessions."`

Follow extension conventions from `home/configs/pi-coding-agent/extensions/firecrawl.ts`:

- Single .ts file, no npm deps
- Export default function(pi: ExtensionAPI)
- Use @sinclair/typebox for parameters
- Import types from @mariozechner/pi-coding-agent

## Acceptance Criteria

1. Extension file exists at `home/configs/pi-coding-agent/extensions/search-sessions.ts`
2. File is valid TypeScript (no syntax errors when pi loads it)
3. `search_sessions` tool registered with query, project, days parameters
4. `read_session` tool registered with path, max_messages parameters
5. BM25 scoring produces ranked results (not random or alphabetical order)
6. Title matches get higher scores than content-only matches (3x boost works)
7. Partial matches score (query 'pnpm lockfile' returns sessions with just 'pnpm', ranked lower)
8. Project filter works: results only contain sessions from matching projects
9. Days filter works: results only contain sessions from last N days
10. Missing index returns clear error message
11. read_session returns condensed conversation from a session file path

## Notes

**2026-04-11T01:21:47Z**

Created search-sessions.ts extension with search_sessions (BM25 ranking, project/days filters, 3x title boost) and read_session (condensed conversation extraction) tools. No npm deps. Extension symlinked to ~/.pi/agent/extensions/.
