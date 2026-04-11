---
id: anm-lftw
status: closed
deps: []
links: []
created: 2026-04-11T02:11:30Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add context7 and githits API tokens to pi wrapper

Add two new env var exports to the `pi` wrapper script in `home/configs/pi-coding-agent/default.nix` (the `writeShellScriptBin "pi"` block, around lines that load ZAI_API_KEY and FIRECRAWL_API_KEY from pass).

Add these lines after the existing FIRECRAWL_API_KEY line:

```
export CONTEXT7_API_KEY="$(pass show api/context7 2>/dev/null || true)"
export GITHITS_API_KEY="$(pass show api/githits 2>/dev/null || true)"
```

These env vars are consumed by the pi-mcp-adapter extension's `resolveHeaders()` and `bearerTokenEnv` mechanisms.

## Files

- `home/configs/pi-coding-agent/default.nix` — the pi wrapper script

## Acceptance Criteria

1. `default.nix` pi wrapper exports `CONTEXT7_API_KEY` loaded via `pass show api/context7`
2. `default.nix` pi wrapper exports `GITHITS_API_KEY` loaded via `pass show api/githits`
3. Existing exports (ZAI_API_KEY, FIRECRAWL_API_KEY) remain unchanged
4. `devenv tasks run home:apply` succeeds

## Notes

**2026-04-11T13:03:23Z**

Added CONTEXT7_API_KEY and GITHITS_API_KEY exports to pi wrapper script in default.nix. Both loaded via pass show with fallback to true. Existing ZAI_API_KEY and FIRECRAWL_API_KEY exports unchanged. home:apply succeeded.
