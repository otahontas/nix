---
id: nix-f9p3
status: open
deps: []
links: []
created: 2026-02-12T19:10:30Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [devenv, dx]
---

# Replace pre-commit with rust-based alternative in devenv

Replace the current pre-commit framework with a Rust-based alternative (e.g. pre-commit-rs) in devenv.nix. Devenv should support this natively via git-hooks.hooks configuration.

## Acceptance Criteria

- Pre-commit hooks use Rust-based tool instead of Python pre-commit
- All existing hooks still run correctly
- Configured in devenv.nix
