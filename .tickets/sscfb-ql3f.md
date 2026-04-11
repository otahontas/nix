---
id: sscfb-ql3f
status: in_progress
deps: [sscfb-cjbq]
links: []
created: 2026-04-10T20:56:15Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq
tags: [ready-for-development]
---
# Convert fish functions to writeShellScriptBin scripts

Convert non-cd fish functions to shell-agnostic scripts via pkgs.writeShellScriptBin.

Functions to convert (by module):
- home/configs/fish/config.fish: listening, nukeport, trash-empty
- home/configs/neovim/: todo, daily, todo_path (todo_path_function_body.fish), daily_path (daily_path_function_body.fish)
- home/configs/fd/: find-and-prune
- home/configs/qpdf/: combine-pdfs-in-folder
- home/configs/yubikey-manager/: yk-status
- home/configs/git/gh.fish: gh-pr-select, gh-pr-copy-url, gh-pr-review, gh-pr-approve-and-merge, gh-run-view, gh-release-slack, format-duration, gh-pr-get-url, gh-repo-get-url, gh-repo-copy-url

For each function:
1. Rewrite as a bash script in writeShellScriptBin
2. Add to home.packages in the module's default.nix
3. Remove the fish function definition

Note: todo and daily call todo_path/daily_path — these can just call the script binaries directly.

## Acceptance Criteria

1. All listed functions available as CLI commands in both fish and bash
2. Original fish function definitions removed
3. Scripts behave identically to the fish functions they replace
4. home-manager build succeeds

