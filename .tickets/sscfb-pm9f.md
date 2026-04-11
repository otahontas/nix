---
id: sscfb-pm9f
status: closed
deps: [sscfb-cjbq]
links: []
created: 2026-04-10T20:56:38Z
type: task
priority: 2
assignee: Otto Ahoniemi
parent: sscfb-cjbq
tags: [ready-for-development]
---

# Add devenv auto-activation for bash

Fish has \_\_devenv_auto that triggers on PWD change via --on-variable PWD.

Bash equivalent: override cd (and pushd/popd) to check for devenv.nix and run devenv shell.

Reference fish implementation in home/configs/fish/config.fish:
function \_\_devenv_auto --on-variable PWD
if test -f "$PWD/devenv.nix"; and not set -q IN_NIX_SHELL
devenv shell
end
end

Add to home/configs/bash/default.nix or home/configs/devenv/default.nix.

## Acceptance Criteria

1. cd-ing into a directory with devenv.nix auto-activates devenv in bash
2. Fish auto-activation still works
3. No double-activation when already in a nix shell
4. home-manager build succeeds

## Notes

**2026-04-11T01:33:42Z**

Added bash devenv auto-activation that overrides cd with \_\_cd_with_devenv which checks for devenv.nix after each directory change. Skips if IN_NIX_SHELL is set.
