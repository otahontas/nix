# Architecture

Two-flake Nix setup for macOS: home-manager (user) + nix-darwin (system), sharing a devenv shell at the repo root.

## Repo layout

Top-level directories and key files.

```
home/            home-manager flake — shells, CLI/GUI tools, catppuccin, pi-coding-agent
  configs/       per-tool directories, each with default.nix (49 configs)
system/          nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
  keyboard/      custom US International no-dead-keys layout
devenv.nix       repo-specific dev shell: tools, tasks, hooks, package wiring
.pi/extensions/ post-edit Pi hook source
devenv.yaml      declares root devenv inputs
lat.md/          this documentation
```

## Devenv

This repo uses devenv for reproducible development environments.

- Use `devenv shell -- <cmd>` to run commands in the dev environment.
- Use `devenv tasks run <task>` to run defined tasks.
- Use `devenv up` for process services.
- Always use devenv to install tools and services or to define tasks.
- This devenv setup keeps repo-specific tools, tasks, and hooks in `devenv.nix`.
- Home Manager installs the global `lat.md` CLI from `home/configs/pi-coding-agent/lat-md.nix`, not from root `devenv.nix`.

## Root devenv setup

Root shell keeps repo-specific devenv behavior in `devenv.nix`, while tracked dotfiles stay editable normal files.

Treefmt config lives under the built-in `treefmt` key in `devenv.nix`; there are no manual wrappers or `repoDevenv.treefmt` overrides.

`.gitignore`, `.nvim.lua`, and `.typos.toml` are tracked normal files; edit them directly.

`.nvim.lua` owns root Neovim LSP setup, including the nixd Home Manager options that previously lived in `.nvim/lsp/nixd.lua`.

The Pi post-edit hook is tracked source at `.pi/extensions/post-edit-hook.ts`, not a generated devenv install.

Treefmt excludes root `AGENTS.md` through global treefmt excludes; typos keeps its own root `AGENTS.md` hook exclude.

Root devenv does not generate repo-local `.pi/mcp.json`, `.pi/agent/AGENTS.md`, `.pi/extensions/lat.ts`, `.pi/extensions/post-edit-hook.ts`, or `.pi/skills/lat-md/SKILL.md`; use built-in lat tools and the `lat` CLI instead.

### Root language tooling

Root language tooling covers repo filetypes that need editor or hook support.

- `devenv.nix` installs LSPs for Fish, JSON, YAML, and TOML, alongside the existing Nix and shell tooling.
- `.nvim.lua` enables `fish_lsp`, `jsonls`, `yamlls`, and `taplo`; YAML includes the custom `yaml.github-action` filetype.
- Hooks check Fish syntax with `fish --no-execute`, JSON syntax with `jq empty`, TOML with `taplo lint`, and YAML with relaxed `yamllint`.
- Treefmt formats TOML with Taplo in addition to existing nixfmt, shfmt, fish_indent, and Prettier.

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

`devenv.nix` defines repo tools, tasks, and hooks without generating repo-local `.pi/mcp.json` on shell entry. It leaves `.gitignore`, `.nvim.lua`, `.typos.toml`, and `.pi/extensions/post-edit-hook.ts` as tracked source files.

### Key takeaway

Global AGENTS.md is a home-manager symlink — never edit it directly. Modify `home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md`, then run `devenv tasks run home:apply`.

This applies broadly in this repo: if `readlink` shows a nix store path, find the source (flake config, home-manager module, or root devenv setting) and change that instead.

## Secrets

LAT tooling gets `LAT_LLM_KEY` from the global Pi wrapper, keeping the value outside git and avoiding per-repo secret setup.

- The Pi wrapper in `home/configs/pi-coding-agent/default.nix` reads pass entry `api/lat-md` directly into `LAT_LLM_KEY`.
- Root `devenv.nix` no longer installs the `lat.md` CLI; Home Manager installs it from `home/configs/pi-coding-agent/lat-md.nix` and exposes it in `home/configs/pi-coding-agent/default.nix`.

## Tasks

Defined in `devenv.nix`, run with `devenv tasks run <task>`:

- `home:apply` — home-manager switch
- `system:apply` — darwin-rebuild switch (requires sudo)
- `nix:format` — treefmt formatters
- `nix:update` — update home/system lockfiles + devenv, apply home-manager, then run `pi update --extensions`
