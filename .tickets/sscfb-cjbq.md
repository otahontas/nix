---
id: sscfb-cjbq
status: in_progress
deps: []
links: []
created: 2026-04-10T20:55:46Z
type: epic
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---
# Share shell config between fish and bash

Many aliases, functions, and tools are fish-only but should also work in bash (used by pi-coding-agent).

Current state: `home/configs/bash/default.nix` only enables bash with no aliases/functions. All shell config lives in fish modules.

## Migration strategy (in dependency order)

1. **sscfb-njl8**: Consolidate aliases into `home/configs/aliases/default.nix`, apply to both `programs.bash.shellAliases` and `programs.fish.shellAliases`
2. **sscfb-ql3f**: Convert non-cd fish functions to `pkgs.writeShellScriptBin` scripts in `home.packages`
3. **sscfb-u6el**: Add bash shell function equivalents for cd-dependent worktree functions (gwnew, gwpr, gwcd) via `programs.bash.bashrcExtra`
4. **sscfb-pm9f**: Add devenv auto-activation for bash (cd override)
5. **sscfb-b5ji** (last): Remove all now-redundant fish-only definitions

See `plans/.ticket-context.md` for full context.

## Acceptance Criteria

1. All child tickets closed
2. `home-manager build --flake .#otahontas` succeeds
3. Opening a bash shell has feature parity with fish for all migrated items
4. Fish shell behavior unchanged

## Children

- sscfb-njl8 [open] Share aliases between fish and bash
- sscfb-pm9f [open] Add devenv auto-activation for bash
- sscfb-ql3f [open] Convert fish functions to writeShellScriptBin scripts
- sscfb-u6el [open] Add bash implementations for cd-dependent worktree functions
- sscfb-b5ji [open] Clean up fish config and remove redundant definitions
