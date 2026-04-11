---
id: Nix-2eqw
status: closed
deps: []
links: []
created: 2026-04-10T10:28:05Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add rtk package to devenv.nix

Add the rtk CLI (Rust Token Killer) to devenv.nix packages so it's available in the dev shell.

Add pkgs.rtk to the existing packages list in devenv.nix. nixpkgs#rtk is v0.30.0, available on aarch64-darwin.

File: devenv.nix (packages list)

## Acceptance Criteria

1. pkgs.rtk is in the packages list in devenv.nix
2. devenv shell -- rtk --version returns a version string
3. Existing devenv tasks still work (devenv tasks list)

## Notes

**2026-04-10T11:00:24Z**

Added pkgs.rtk to devenv.nix packages list. Verified: rtk --version returns 0.30.0, devenv tasks list works, pre-commit hooks pass.
