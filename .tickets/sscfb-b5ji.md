---
id: sscfb-b5ji
status: closed
deps: [sscfb-njl8, sscfb-ql3f, sscfb-u6el, sscfb-pm9f]
links: []
created: 2026-04-10T20:56:56Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq # Share shell config between fish and bash
tags: [ready-for-development]
---

# Clean up fish config and remove redundant definitions

Remove all fish-only definitions that are now provided by shared aliases, writeShellScriptBin scripts, or bash-specific implementations from the other tickets.

## Files to clean up

### `home/configs/fish/config.fish`

Remove these function definitions (now writeShellScriptBin scripts from sscfb-ql3f):

- `listening`
- `nukeport`
- `trash-empty`
- `__devenv_auto` (moved to bash equiv in sscfb-pm9f; fish version stays as-is actually — keep this)

Keep in fish/config.fish:

- `set -gx SHELL (which fish)`
- `fish_vi_key_bindings`
- `set -g fish_greeting` + `printf '\33c\e[3J'`
- `__devenv_auto` (fish-native, stays)

### `home/configs/neovim/default.nix`

Remove `programs.fish.interactiveShellInit` (config.fish content), `programs.fish.functions.todo_path`, `programs.fish.functions.daily_path` — all now scripts.

### `home/configs/fd/default.nix`

Remove `programs.fish.interactiveShellInit` (config.fish content for `find-and-prune`, now a script).

### `home/configs/qpdf/default.nix`

Remove `programs.fish.interactiveShellInit` (config.fish content for `combine-pdfs-in-folder`, now a script).

### `home/configs/yubikey-manager/default.nix`

Remove `programs.fish.functions.yk-status` — now a writeShellScriptBin script.

### `home/configs/git/default.nix`

Remove `programs.fish.interactiveShellInit` (worktree.fish + gh.fish content). Worktree functions that cd stay as fish functions via separate mechanism; gh-\* functions are now scripts.

### Delete orphaned .fish files

- `home/configs/fd/config.fish` (find-and-prune migrated)
- `home/configs/qpdf/config.fish` (combine-pdfs-in-folder migrated)
- `home/configs/neovim/config.fish` (todo/daily migrated)
- `home/configs/neovim/todo_path_function_body.fish` (migrated)
- `home/configs/neovim/daily_path_function_body.fish` (migrated)
- `home/configs/yubikey-manager/yk-status.fish` (migrated)
- `home/configs/git/gh.fish` (all gh-\* functions migrated to scripts)

Keep:

- `home/configs/fish/config.fish` (fish-specific init)
- `home/configs/git/worktree.fish` (cd-dependent, fish versions stay)
- `home/configs/devenv/devenv-tasks-run.fish` (fish completion)

## Acceptance Criteria

1. `home-manager build --flake .#otahontas` succeeds
2. No deleted `.fish` files are referenced from any `.nix` file
3. `home/configs/fish/config.fish` only contains fish-specific init (SHELL export, vi bindings, greeting, \_\_devenv_auto)
4. All migrated commands still work in fish (they resolve to the writeShellScriptBin binaries)
5. All migrated commands work in bash

## Blockers

- sscfb-njl8 [open] Share aliases between fish and bash
- sscfb-ql3f [open] Convert fish functions to writeShellScriptBin scripts
- sscfb-u6el [open] Add bash implementations for cd-dependent worktree functions
- sscfb-pm9f [open] Add devenv auto-activation for bash

## Notes

**2026-04-11T02:04:45Z**

All cleanup verified: orphaned .fish files already deleted, config.fish contains only fish-specific init, all nix modules cleaned of redundant fish references, build and lint pass.
