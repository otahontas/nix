---
id: nix-o5w3
status: open
deps: []
links: []
created: 2026-02-13T11:48:09Z
type: chore
priority: 2
assignee: Otto Ahoniemi
---

# Move tk tool from global install to repo-specific tooling

The tk CLI ticket tool is currently installed globally. Move it to be a repo-specific tool instead, e.g. via devenv or a flake app.

## Acceptance Criteria

- tk is no longer globally installed\n- tk is available when entering the repo (e.g. via devenv/direnv)\n- Existing tickets in .tickets/ continue to work
