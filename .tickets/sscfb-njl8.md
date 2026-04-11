---
id: sscfb-njl8
status: closed
deps: [sscfb-cjbq]
links: []
created: 2026-04-10T20:55:59Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq  # Share shell config between fish and bash
tags: [ready-for-development]
---
# Share aliases between fish and bash

Create `home/configs/aliases/default.nix` with a single `let` binding that defines all aliases, then apply them to both `programs.bash.shellAliases` and `programs.fish.shellAliases`.

## Current fish-only aliases to consolidate

| Alias | Expansion | Current location |
|-------|-----------|-----------------|
| `cat` | `bat` | `home/configs/bat/default.nix` |
| `pic` | `pi -c` | `home/configs/pi-coding-agent/default.nix` |
| `pir` | `pi -r` | `home/configs/pi-coding-agent/default.nix` |
| `gsw` | `git sw` | `home/configs/git/default.nix` |
| `gwcd` | `git-worktree-cd` | `home/configs/git/default.nix` |
| `gwnew` | `git-worktree-new` | `home/configs/git/default.nix` |
| `gwpr` | `git-worktree-pr` | `home/configs/git/default.nix` |
| `gwprune` | `git-worktree-prune` | `home/configs/git/default.nix` |

## Steps

1. Create `home/configs/aliases/default.nix` with a `sharedAliases` attrset
2. Set `programs.bash.shellAliases = sharedAliases` and `programs.fish.shellAliases = sharedAliases`
3. Remove `programs.fish.shellAliases` from `home/configs/bat/default.nix`
4. Remove `programs.fish.shellAliases` from `home/configs/pi-coding-agent/default.nix`
5. Remove `programs.fish.shellAliases` from `home/configs/git/default.nix`

## Acceptance Criteria

1. `home-manager build --flake .#otahontas` succeeds
2. No `programs.fish.shellAliases` remains in bat, pi-coding-agent, or git modules
3. No `programs.bash.shellAliases` in any module except `home/configs/aliases/default.nix`
4. All 8 aliases resolve in both fish and bash (verify with `type <alias>` in each shell)

## Blockers

- sscfb-cjbq [open] Share shell config between fish and bash

## Blocking

- sscfb-b5ji [open] Clean up fish config and remove redundant definitions

## Notes

**2026-04-11T01:16:54Z**

Created home/configs/aliases/default.nix with sharedAliases attrset. Removed fish.shellAliases from bat, pi-coding-agent, and git modules. Build passes.
