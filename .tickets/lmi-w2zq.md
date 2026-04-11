---
id: lmi-w2zq
status: closed
deps: []
links: []
created: 2026-04-11T09:27:22Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add lat.md CLI to pi wrapper PATH

Add the lat.md npm package (Agent Lattice knowledge graph CLI) to the pi wrapper PATH so it's available in all pi sessions.

lat.md is not in nixpkgs — needs to be built with buildNpmPackage similar to how pi-coding-agent is built in default.nix. The npm package name is 'lat.md' (v0.11.0).

Once built, add the resulting bin to the pi wrapper PATH in the writeShellScriptBin "pi" block, alongside nodejs_24, poppler-utils, and ast-grep.

Files:

- home/configs/pi-coding-agent/default.nix — add buildNpmPackage for lat.md and include in PATH
- home/configs/pi-coding-agent/pi-package/ — reference pattern for how pi-coding-agent is built

## Acceptance Criteria

1. lat.md is built with buildNpmPackage in default.nix with correct npmDepsHash
2. `which lat` returns a path inside a pi session
3. `lat --version` returns v0.11.0 (or latest) inside a pi session
4. Existing pi wrapper still works (node, ast-grep, poppler still on PATH)
5. `devenv tasks run home:apply` succeeds without errors

## Notes

**2026-04-11T10:03:55Z**

Built lat.md 0.11.0 with buildNpmPackage, added to pi wrapper PATH. Verified: lat --version returns 0.11.0.
