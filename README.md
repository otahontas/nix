# nix config

nix-darwin + home-manager based nix setup for macos. System config and user config are separate — system needs sudo, user config doesn't.

main goodies: neovim, fish, pi-coding assistant, catppuccin, gpg based git & ssh setup.

configs can be found from:

- **`home/`** - home-manager config for CLI and GUI apps (no sudo needed)
- **`system/`** - nix-darwin config for system settings (needs sudo)

All CLI and GUI apps are managed through home-manager.

dev setup is handled with devenv.

## Structure

```
home/
  flake.nix           # Home-manager entry point
  configs/            # Per-tool configurations
    bash/
    zsh/
    git/
    ...

system/
  flake.nix           # Nix-darwin entry point
  ...
```

As with many nix setups, don't just blindly copy and apply.
