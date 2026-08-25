# Architecture

Two-flake Nix setup for macOS: Home Manager owns user tools, nix-darwin owns system state, and root devenv owns repository development behavior.

## Repository model

Each configuration layer has one owner, preventing root development tooling from leaking into user or system state.

- `home/` contains the Home Manager flake and per-tool configs.
- `system/` contains nix-darwin settings and keyboard data.
- `devenv.nix` imports tracked `.devenv-modules/` for root packages, tasks, formatting, and hooks.
- `.nvim.lua`, `.nvim/`, and `.pi/` contain tracked repository-local editor and Pi behavior.

## Root devenv setup

Root devenv behavior stays in tracked source rather than generated wrappers or shell-entry mutations.

Treefmt configuration lives in `.devenv-modules/treefmt.nix`. Generated `.devenv/`, lock files, and root `AGENTS.md` are excluded where needed; tracked modules remain normal formatted files.

`.nvim.lua` loads repository modules from `.nvim/lua/` and LSP overrides from `.nvim/lsp/`. Home Manager owns global Neovim behavior; root files add only repository behavior.

### Root language tooling

Editor diagnostics and commit hooks use matching engines where practical; exceptions below record only constraints that source configuration cannot explain.

Manual hook runs use `prek`. `.pre-commit-config.yaml` is generated configuration, not the command to run.

#### Lock file diagnostics

Generated lock files intentionally receive no editor or hook diagnostics.

Review lock changes through their owning update commands instead of adding formatters, schema checks, or filetype overrides.

#### Nix diagnostics

Nix uses nixd in Neovim, Statix through nvim-lint, and deadnix, Statix, and treefmt hooks.

Statix remains alongside nixd because it catches style checks that nixd misses; deadnix remains the hook gate for unused Nix code.

#### Markdown diagnostics

Markdown uses markdownlint in hooks and repository-local nvim-lint.

The local linter passes file paths instead of stdin so `.markdownlintignore` applies consistently.

#### Bash diagnostics

Bash uses BashLS in Neovim and ShellCheck hooks with matching default severity, external source following, and per-file source paths.

#### Fish diagnostics

Fish uses fish-lsp in Neovim plus `fish --no-execute` in hooks and nvim-lint.

Keep the parser check until fish-lsp provides a stable batch diagnostics command.

#### JSON diagnostics

JSON uses jsonls in Neovim and config-file-validator in hooks for syntax and matched schemas.

The standalone `vscode-json-languageserver` package is required because the extracted bundle fails at startup.

#### Config schema diagnostics

JSON, YAML, and TOML use config-file-validator in hooks and SchemaStore.nvim in Neovim.

Unknown files receive syntax checks only. `devenv.yaml` has an explicit schema mapping. The validator comes from the `otahontas-nixpkgs` devenv input.

#### Keyboard layout diagnostics

Apple keylayout data intentionally skips generic XML linting.

The generated file contains Apple-valid control references and CR line endings rejected by generic XML tools; see [[system-config#Keyboard layout file]].

#### Lua diagnostics

Lua uses EmmyLua in Neovim and hooks, with `.emmyrc.json` as the shared source of truth for LuaJIT, globals, ignored paths, and plugin runtime libraries.

`mini.nvim`'s `mini/base16.lua` stays ignored because EmmyLua 0.23.2 hangs while indexing it. Remove the ignore when upstream handles the module.

#### TypeScript diagnostics

TypeScript checks root and Home Manager Pi extensions against Pi's installed package types rather than local ambient declarations.

The generated `.devenv/pi-node-modules` symlink exposes those types. `home/flake.lock` owns the Pi revision, while root devenv follows `home/pi-nix`.

The hook runs the full project for staged TypeScript changes; Neovim uses the same `tsconfig.json` through `ts_ls`.

#### TOML diagnostics

TOML uses Taplo for formatting, editor diagnostics, and hook linting, with config-file-validator adding matched schema checks.

## Flake ownership

Home, system, and root devenv use unstable nixpkgs while each lock file owns its layer's inputs.

The Home Manager flake owns Pi and user-tool inputs. Root devenv imports `./home` only so `pi-nix` follows the Home Manager revision used by installed Pi extensions.

## AGENTS.md pipeline

Pi concatenates global and repository `AGENTS.md` files, so each file contains only rules for its scope.

Home Manager links `home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md` and `APPEND_SYSTEM.md` into global Pi state. Root `AGENTS.md` remains tracked and carries repository lat.md workflow.

Edit Home Manager-managed source files at their tracked paths, then run `devenv tasks run home:apply`; edit root files directly.
