---
id: sscfb-cjbq
status: open
deps: []
links: []
created: 2026-04-10T20:55:46Z
type: epic
priority: 2
assignee: Otto Ahoniemi
---
# Share shell config between fish and bash

Many aliases, functions, and tools are fish-only but should also work in bash (used by pi-coding-agent).

Migration strategy:
1. Share aliases between fish and bash via a single nix binding
2. Convert non-cd functions to writeShellScriptBin scripts (shell-agnostic)
3. Add bash implementations for cd-dependent functions (gwnew, gwpr, gwcd)
4. Clean up redundant fish function definitions

See plans/.ticket-context.md for full context.

## Acceptance Criteria

1. All shared aliases work in both fish and bash
2. All non-cd functions work in both fish and bash as CLI commands
3. cd-dependent functions (gwnew, gwpr, gwcd) work in bash
4. No functional regression in fish
5. home-manager build succeeds

