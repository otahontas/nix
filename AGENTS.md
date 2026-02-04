Nix setup for macOS with strict user separation:

## User separation

- **Admin user** (`otahontas-admin`) - only account with sudo access (by design)
  - Manages nix-darwin config in `system/` folder
  - Only system related configs
- **Primary user** (`otahontas`) - day-to-day account without sudo
  - Manages home-manager config in `home/` folder
  - Installs all CLI tools, graphical apps via home-manager

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
