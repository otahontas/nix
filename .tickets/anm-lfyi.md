---
id: anm-lfyi
status: closed
deps: [anm-62nt]
links: []
created: 2026-04-11T09:22:25Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add chrome-devtools MCP server to mcp.json

Add the chrome-devtools MCP server entry to `home/configs/pi-coding-agent/mcp.json` (created by ticket anm-62nt).

Chrome DevTools MCP is a stdio-based server (runs locally, no HTTP, no API key). It lets the coding agent control and inspect a live Chrome browser: navigate pages, take screenshots, run performance traces, inspect network requests and console output, run Lighthouse audits, etc. See https://github.com/ChromeDevTools/chrome-devtools-mcp

The pi wrapper already has `nodejs_24/bin` in PATH (provides node and its package runner), and pi-mcp-adapter handles binary resolution automatically via `resolveNpxBinary()` in `server-manager.ts`.

Add this entry to the `mcpServers` block in mcp.json:

```json
"chrome-devtools": {
  "command": "npx",
  "args": ["-y", "chrome-devtools-mcp@latest"]
}
```

This goes into the same mcp.json file that ticket anm-62nt creates. This ticket ensures the file ends up with all three servers (context7, githits, chrome-devtools) in one config.

## Files

- `home/configs/pi-coding-agent/mcp.json` — add chrome-devtools entry alongside context7 and githits

## Acceptance Criteria

1. `mcp.json` contains `chrome-devtools` entry: `"command": "npx"`, `"args": ["-y", "chrome-devtools-mcp@latest"]`
2. `mcp.json` also contains `context7` and `githits` entries from ticket anm-62nt
3. After `devenv tasks run home:apply`, `~/.pi/agent/mcp.json` has all three servers
4. `devenv tasks run home:apply` succeeds

## Notes

**2026-04-11T12:35:05Z**

Merged into anm-62nt — all three servers (context7, githits, chrome-devtools) go into one mcp.json file in a single ticket.
