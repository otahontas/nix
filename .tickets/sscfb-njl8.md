---
id: sscfb-njl8
status: open
deps: [sscfb-cjbq]
links: []
created: 2026-04-10T20:55:59Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq
---
# Share aliases between fish and bash

Define aliases once in a nix let-binding and apply to both programs.bash.shellAliases and programs.fish.shellAliases.

Currently fish-only aliases scattered across modules:
- home/configs/bat/default.nix: cat → bat
- home/configs/pi-coding-agent/default.nix: pic → pi -c, pir → pi -r
- home/configs/git/default.nix: gsw → git sw, gwcd, gwnew, gwpr, gwprune

Option A: Move all aliases to a single shared module (e.g. home/configs/aliases/default.nix)
Option B: Define a sharedAliases attr in each module and merge them

Option A is simpler and keeps alias definitions centralized.

## Acceptance Criteria

1. All aliases defined once, shared between fish and bash
2. No programs.fish.shellAliases remain in individual modules (except fish-only ones if any)
3. home-manager build succeeds
4. Aliases work in both fish and bash shells

