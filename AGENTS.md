Nix setup for macOS. System config (nix-darwin) and user config (home-manager) are separate — system needs sudo, user config doesn't.

## Config layout

- **`home/`** — home-manager config for CLI and GUI apps (no sudo)
- **`system/`** — nix-darwin config for system settings (needs sudo)

All CLI and GUI apps are managed through home-manager.
All CLI and GUI apps are managed through home-manager.

## Development environment

- Pre-commit hooks configured in `devenv.nix` via `git-hooks.hooks`
- Linter configs (typos, etc.) - either standalone files (`.typos.toml`) or inline in devenv
- `deadnix` checks for unused Nix declarations - use `_` for intentionally unused lambda args

## Investigating nixpkgs packages for darwin

- `nix search nixpkgs <name>` - shows packages but doesn't mean they work on darwin
- `nix eval --json nixpkgs#<pkg>.meta.platforms` - check actual platform support
- Many packages have `-bin` variants for darwin (e.g., `ghostty` is Linux-only, `ghostty-bin` works on darwin)
- `nix build --no-link --print-out-paths nixpkgs#<pkg>` then check for `Applications/*.app` - verifies GUI app bundle exists
- `NIXPKGS_ALLOW_UNFREE=1 nix build --impure ...` - for testing unfree packages

## Committing and pushing

- All commits can be pushed directly to default branch (main) in github
- This project uses a CLI ticket system for task management. Run `tk help` when you need to use it.
