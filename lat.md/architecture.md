# Architecture

Two-flake Nix setup for macOS: home-manager (user) + nix-darwin (system), sharing a devenv shell at the repo root.

## Repo layout

Top-level directories and key files.

```
home/            home-manager flake — shells, CLI/GUI tools, catppuccin, pi-coding-agent
  configs/       per-tool directories, each with default.nix (48 configs)
system/          nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
  keyboard/      custom US International no-dead-keys layout
devenv.nix       repo-specific dev shell: tools, hooks, generated files, tasks, lat.md support
devenv.yaml      declares root devenv inputs
lat.md/          this documentation
```

## Devenv

This repo uses devenv for reproducible development environments.

- Use `devenv shell -- <cmd>` to run commands in the dev environment.
- Use `devenv tasks run <task>` to run defined tasks.
- Use `devenv up` for process services.
- Always use devenv to install tools and services or to define tasks.
- This devenv setup keeps repo-specific tools, hooks, generated files, and tasks in `devenv.nix`.
  - Customize root devenv behavior in `devenv.nix`; generated files are rebuilt on shell entry.

## Root devenv setup

Root shell keeps repo-specific devenv behavior in `devenv.nix`, so generated files, hooks, tools, tasks, and package wiring live in one file.

Configurable repo options still live under `repoDevenv.<name>` inside `devenv.nix`:

```nix
repoDevenv.treefmt.programs = { ... };
repoDevenv.gitignore.extraEntries = [ ... ];
```

Generated files stay store-backed. Don't edit `.gitignore`, `.nvim.lua`, `.pi/mcp.json`, or `.pi/extensions/post-edit-hook.ts` directly; update `devenv.nix` and re-enter the shell.

Root devenv does not generate repo-local `.pi/agent/AGENTS.md`, `.pi/extensions/lat.ts`, or `.pi/skills/lat-md/SKILL.md`; use built-in lat tools and the `lat` CLI instead.

## Flakes

Both flakes pin `nixpkgs-unstable` independently. `home/` pulls extra inputs:

- **catppuccin / pi-catppuccin** — global theme (macchiato/blue) across terminal, editor, pi TUI
- **kanttiinit-cli** — personal CLI tool
- **pi-nix** — external flake at `github:lukasl-dev/pi.nix`; supplies the Pi package and Home Manager module
- **brew-nix** — package overlay used by `mas` for Mac App Store installs

## AGENTS.md pipeline

Pi loads AGENTS.md from multiple locations (global + parent dirs + cwd), all concatenated. This repo uses the global managed AGENTS.md; repo-local operating rules live in lat.md.

### Repository operating rules

The retired root `AGENTS.md` carried repo-local rules that now live here.

- All commits can be pushed directly to default branch (`main`) in GitHub.
- Run `devenv tasks run home:apply` after changing Home Manager config.

### Global: home-manager

`home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md` → symlinked to `~/.pi/agent/AGENTS.md` by home-manager. Edit the source file, then `devenv tasks run home:apply`.

### Project: root devenv file

`devenv.nix` symlinks repo `.pi/mcp.json` and `.pi/extensions/post-edit-hook.ts` on shell entry. It no longer generates project-level AGENTS.md, `lat.ts`, or `lat-md` skill files.

### Key takeaway

Global AGENTS.md is a home-manager symlink — never edit it directly. Modify `home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md`, then run `devenv tasks run home:apply`.

This applies broadly in this repo: if `readlink` shows a nix store path, find the source (flake config, home-manager module, or root devenv setting) and change that instead.

## Secrets

LAT tooling gets `LAT_LLM_KEY` from the global Pi wrapper, keeping the value outside git and avoiding per-repo secret setup.

- The Pi wrapper in `home/configs/pi-coding-agent/default.nix` reads pass entry `api/lat-md` directly into `LAT_LLM_KEY`.
- Root devenv installs the `lat` CLI but no longer declares or exports a repo-specific `LAT_LLM_KEY`.

## Tasks

Defined in `devenv.nix`, run with `devenv tasks run <task>`:

- `home:apply` — home-manager switch
- `system:apply` — darwin-rebuild switch (requires sudo)
- `nix:format` — treefmt formatters
- `nix:update` — update home/system lockfiles + devenv, apply home-manager, then run `pi update --extensions`
