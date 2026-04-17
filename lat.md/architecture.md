# Architecture

Two-flake Nix setup for macOS: home-manager (user) + nix-darwin (system), sharing a devenv shell at the repo root.

## Repo layout

Top-level directories and key files.

```
home/            home-manager flake — shells, CLI/GUI tools, catppuccin, pi-coding-agent
  configs/       per-tool directories, each with default.nix (42 configs)
  packages/      manual npm derivations (pi-mcp-adapter, pi-web-access)
system/          nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
  keyboard/      custom US International no-dead-keys layout
devenv.nix       repo-specific dev shell: typos config, fish_indent, tasks
devenv.yaml      imports devenv-base as flake input
scripts/         update-manual-packages.sh — bumps npm packages not in nixpkgs
lat.md/          this documentation
```

## devenv-base

Shared module collection at `github:otahontas/devenv-base`, imported in `devenv.yaml`. Provides languages, formatters, git hooks, neovim, AI tooling, and more.

Each module lives in `modules/<name>/` and exposes options under the `devenv-base.<name>` namespace. To extend a module, set its options in `devenv.nix`:

```nix
devenv-base.agents-md.extraEntries = [ ... ];
devenv-base.treefmt.programs = { ... };
```

Check the module's `default.nix` for available options. Don't edit generated files directly — extend the module config and rebuild.

## Flakes

Both flakes pin `nixpkgs-unstable` independently. `home/` pulls extra inputs:

- **catppuccin / pi-catppuccin** — global theme (macchiato/blue) across terminal, editor, pi TUI
- **kanttiinit-cli** — personal CLI tool
- **brew-nix** — package overlay used by `mas` for Mac App Store installs

## AGENTS.md pipeline

Pi loads AGENTS.md from multiple locations (global + parent dirs + cwd), all concatenated. This repo has two managed layers.

### Global: home-manager

`home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md` → symlinked to `~/.pi/agent/AGENTS.md` by home-manager. Edit the source file, then `devenv tasks run home:apply`.

### Project: devenv-base module

`devenv-base` provides `modules/agents-md/` which generates a project-level AGENTS.md at `${DEVENV_ROOT}/.pi/agent/AGENTS.md` on every `devenv shell` entry:

1. Base content from `modules/agents-md/BASE_AGENTS.md`
2. Appends any strings from `devenv-base.agents-md.extraEntries`
3. Writes result to nix store, `enter-shell.sh` symlinks it into `.pi/agent/`

To add project-specific instructions, extend in `devenv.nix`:

```nix
devenv-base.agents-md.extraEntries = [
  "## My section"
  ""
  "- Some instruction"
];
```

### Key takeaway

Both AGENTS.md files are nix store symlinks — never edit them directly. Always modify the source (`GLOBAL_AGENTS.md` for global, `devenv.nix` extra entries for project) and rebuild.

This applies broadly in this repo: if `readlink` shows a nix store path, find the source (flake config, home-manager module, or devenv-base option) and change that instead.

## Tasks

Defined in `devenv.nix`, run with `devenv tasks run <task>`:

- `home:apply` — home-manager switch
- `system:apply` — darwin-rebuild switch (requires sudo)
- `nix:update` — update all lockfiles + manual npm packages (pi-coding-agent pinned in `pi-package/`, pi-mcp-adapter and pi-web-access pinned via `fetchFromGitHub` in `home/packages/`)
