# nix config

nix-darwin + home-manager based nix setup for macos. Uses strict user separation: an admin account handles system-level stuff, while my daily-driver account stays sudo-free.

main goodies: neovim, fish, pi-coding assistant, catppuccin, gpg based git & ssh setup.

configs can be found from:

- **`home/`** - home-manager config for CLI and GUI apps (runs as primary user)
- **`system/`** - nix-darwin config for system settings (runs as admin)

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
