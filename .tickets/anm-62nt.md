---
id: anm-62nt
status: closed
deps: [anm-lftw]
links: []
created: 2026-04-11T02:11:49Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add mcp.json with context7, githits, and chrome-devtools servers

Create `home/configs/pi-coding-agent/mcp.json` (new file) with three MCP server definitions and wire it into `default.nix` so it deploys to `~/.pi/agent/mcp.json` via `home.file`.

The pi-mcp-adapter reads `~/.pi/agent/mcp.json` on startup. It supports env var interpolation in headers (`${VAR}`) and `bearerTokenEnv` for Bearer auth (see `server-manager.ts` `resolveHeaders()` and `createHttpTransport()`).

**Context7** — remote HTTP, API key passed as a custom header:

```json
"context7": {
  "url": "https://mcp.context7.com/mcp",
  "headers": {
    "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
  }
}
```

**GitHits** — remote HTTP, Bearer token via env var:

```json
"githits": {
  "url": "https://mcp.githits.com/",
  "auth": "bearer",
  "bearerTokenEnv": "GITHITS_API_KEY"
}
```

**Chrome DevTools** — stdio-based, no API key, uses local npx:

```json
"chrome-devtools": {
  "command": "npx",
  "args": ["-y", "chrome-devtools-mcp@latest"]
}
```

Depends on ticket anm-lftw (env vars must be available in the pi process).

## Files

- `home/configs/pi-coding-agent/mcp.json` — new file, MCP server definitions
- `home/configs/pi-coding-agent/default.nix` — add `home.file.".pi/agent/mcp.json".source = ./mcp.json;`

## Acceptance Criteria

1. `home/configs/pi-coding-agent/mcp.json` exists with `mcpServers` containing `context7`, `githits`, and `chrome-devtools` entries matching the JSON snippets above
2. `default.nix` has `home.file.".pi/agent/mcp.json".source = ./mcp.json;` in the `file` attrset
3. After `devenv tasks run home:apply`, `~/.pi/agent/mcp.json` contains all three server definitions
4. `devenv tasks run home:apply` succeeds

## Notes

**2026-04-11T13:09:54Z**

Created mcp.json with context7 (HTTP + API key header), githits (HTTP + bearer token), and chrome-devtools (stdio/npx) server definitions. Wired into default.nix via home.file. Verified with home:apply — file deploys to ~/.pi/agent/mcp.json with all three entries.
