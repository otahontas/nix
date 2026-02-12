---
id: nix-r1bd
status: open
deps: []
links: []
created: 2026-02-12T20:11:54Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [nix, packages, dx]
---

# Create manual package update script

Create scripts/update-manual-pkgs.sh that uses nix-update to check and update the 6 manual package definitions in home/packages/. Add nix-update to devenv.nix packages and add a nix:update-manual task. See docs/ni-a5kc-manual-package-updates.md for full design.

## Acceptance Criteria

- Script updates GitHub packages (lulu, blockblock, pearcleaner, pareto-security) automatically via nix-update
- Script scrapes Mozilla Archive for latest Firefox DevEdition version
- MacWhisper skipped with message (no public API for build numbers)
- nix:update-manual devenv task added
- All updated packages build successfully
