# nix config

nix-darwin + home-manager setup for macOS. Two flakes — one for the user, one for the system — sharing a devenv shell.

- **`home/`** — home-manager config for CLI and GUI apps (shells, editor, pi-coding-agent, catppuccin)
- **`system/`** — nix-darwin config for system settings and global installs

## What's included

See `lat.md/` for full documentation. Briefly:

- **Shells** — fish with per-tool integrations
- **Editor** — neovim with LSPs for Nix, shell, Lua
- **Dev env** — devenv with languages, formatters, git hooks
- **AI tooling** — pi coding agent with extensions and skills
- **Theme** — catppuccin across all apps
- **GPG/SSH** — YubiKey-based git signing and SSH

## Quick start

```sh
devenv shell                    # enter dev environment
devenv tasks run home:apply     # apply home-manager config
devenv tasks run system:apply   # apply system config (requires sudo)
```
