# Architecture

Nix-managed macOS workstation. Two flakes — one for the user, one for the system — sharing a devenv shell at the repo root.

## Repo layout

Directory tree and what each top-level folder contains.

```
home/       home-manager flake — shells, CLI tools, GUI apps, pi-coding-agent
system/     nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
devenv.nix  shared dev shell, tasks, linters
scripts/    update-manual-packages.sh
```

## Flakes

Both flakes pin `nixpkgs-unstable` independently. `home/` pulls extra inputs: catppuccin, brew-nix, kanttiinit-cli, pi-catppuccin.

Apply commands live in `devenv.nix` tasks:

- `devenv tasks run home:apply` — home-manager switch
- `devenv tasks run system:apply` — darwin-rebuild switch
- `devenv tasks run nix:update` — update all lockfiles + manual packages

## Config auto-import

`home/flake.nix` auto-imports every `.nix` file under `home/configs/` via `lib.filesystem.listFilesRecursive`. Adding a new tool = adding a directory there — no manual registration.

## Manual package updates

`scripts/update-manual-packages.sh` bumps npm packages not in nixpkgs (pi-coding-agent, pi-mcp-adapter). Run via `devenv tasks run nix:update`.
