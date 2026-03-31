# nix config

nix-darwin + home-manager based nix setup for macos. main goodies: devenv, neovim, fish, pi-coding assistant, catppuccin, gpg based git & ssh setup.

config is separated to two folders:

- **`home/`** - home-manager config for CLI and GUI apps for single user
- **`system/`** - nix-darwin config for system settings / global installs

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
