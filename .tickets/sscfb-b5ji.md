---
id: sscfb-b5ji
status: open
deps: [sscfb-njl8, sscfb-ql3f, sscfb-u6el, sscfb-pm9f]
links: []
created: 2026-04-10T20:56:56Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq
---
# Clean up fish config and remove redundant definitions

After aliases, functions, and scripts are migrated:

1. Remove fish-only function definitions that are now scripts (listening, nukeport, trash-empty, todo, daily, todo_path, daily_path, find-and-prune, combine-pdfs-in-folder, yk-status, all gh-* functions, format-duration, gwprune)
2. Remove fish-only aliases that are now shared (cat, pic, pir, gsw, gwcd, gwnew, gwpr, gwprune)
3. Remove programs.fish.shellAliases from bat, pi-coding-agent, git modules
4. Remove programs.fish.functions from yubikey-manager module
5. Remove programs.fish.interactiveShellInit from fd, qpdf, neovim, git modules (for migrated functions)
6. Keep fish-specific init: vi key bindings, SHELL export, greeting clear, __devenv_auto
7. Keep fish completions (devenv-tasks-run.fish, git worktree completions)

This must be done LAST after all other migration tickets are complete.

## Acceptance Criteria

1. No redundant fish-only definitions remain for migrated features
2. Fish shell still works identically to before
3. Bash shell has feature parity for all migrated items
4. home-manager build succeeds
5. No dead code or orphaned .fish files

