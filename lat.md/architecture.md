# Architecture

Two-flake Nix setup for macOS: home-manager (user) + nix-darwin (system), sharing a devenv shell at the repo root.

## Repo layout

Top-level directories and key files.

```
home/            home-manager flake — shells, CLI/GUI tools, catppuccin, pi-coding-agent
  configs/       per-tool directories, each with default.nix (48 configs)
system/          nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
  keyboard/      custom US International no-dead-keys layout
devenv.nix       repo-specific dev shell: imports local modules, typos config, treefmt overrides, tasks
devenv.yaml      declares root devenv inputs and enables SecretSpec
devenv/modules/  inlined root devenv modules: languages, formatters, hooks, AI tooling
secretspec.toml  pass-backed secret requirements for the root shell
lat.md/          this documentation
```

## Root devenv modules

Root shell imports local modules from `devenv/modules/`, so this repo does not depend on an external shared base module.

Each module lives in `devenv/modules/<name>/`. Options that remain configurable live under the `repoDevenv.<name>` namespace. To extend a module, set its options in `devenv.nix`:

```nix
repoDevenv.agents-md.extraEntries = [ ... ];
repoDevenv.treefmt.programs = { ... };
repoDevenv.gitignore.extraEntries = [ ... ];
```

Check the module's `default.nix` for available options. Don't edit generated files directly — extend the module config and rebuild.

## Flakes

Both flakes pin `nixpkgs-unstable` independently. `home/` pulls extra inputs:

- **catppuccin / pi-catppuccin** — global theme (macchiato/blue) across terminal, editor, pi TUI
- **kanttiinit-cli** — personal CLI tool
- **pi-nix** — external flake at `github:lukasl-dev/pi.nix`; supplies the Pi package and Home Manager module
- **brew-nix** — package overlay used by `mas` for Mac App Store installs

## AGENTS.md pipeline

Pi loads AGENTS.md from multiple locations (global + parent dirs + cwd), all concatenated. This repo has two managed layers.

### Global: home-manager

`home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md` → symlinked to `~/.pi/agent/AGENTS.md` by home-manager. Edit the source file, then `devenv tasks run home:apply`.

### Project: root devenv module

`devenv/modules/agents-md/` generates a project-level AGENTS.md at `${DEVENV_ROOT}/.pi/agent/AGENTS.md` on every `devenv shell` entry:

1. Base content from `devenv/modules/agents-md/BASE_AGENTS.md`
2. Appends any strings from `repoDevenv.agents-md.extraEntries`
3. Writes result to nix store, `enter-shell.sh` symlinks it into `.pi/agent/`

To add project-specific instructions, extend in `devenv.nix`:

```nix
repoDevenv.agents-md.extraEntries = [
  "## My section"
  ""
  "- Some instruction"
];
```

### Key takeaway

Both AGENTS.md files are nix store symlinks — never edit them directly. Always modify the source (`GLOBAL_AGENTS.md` for global, `repoDevenv.agents-md.extraEntries` or local module files for project) and rebuild.

This applies broadly in this repo: if `readlink` shows a nix store path, find the source (flake config, home-manager module, or root devenv module option) and change that instead.

## Secrets

Root devenv exports only `LAT_LLM_KEY` for LAT tooling. SecretSpec declares the requirement while `pass` stores the value outside git.

- `secretspec.toml` declares `LAT_LLM_KEY` in the default profile.
- `devenv.yaml` enables SecretSpec with `provider: pass` and `profile: default`.
- `devenv.nix` exports `config.secretspec.secrets.LAT_LLM_KEY` directly, so a missing value fails instead of falling back to a blank string.

## Tasks

Defined in `devenv.nix`, run with `devenv tasks run <task>`:

- `home:apply` — home-manager switch
- `system:apply` — darwin-rebuild switch (requires sudo)
- `nix:update` — update home/system lockfiles + devenv, apply home-manager, then run `pi update --extensions`
