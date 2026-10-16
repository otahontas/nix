# Architecture

Two-flake Nix setup for macOS: Home Manager owns user tools, nix-darwin owns system state, and root devenv owns repository development behavior.

## Repository model

Each configuration layer has one owner, preventing root development tooling from leaking into user or system state.

- [[home/flake.nix]] owns Home Manager inputs and imports [[home/configs|per-tool configs]].
- [[system/flake.nix]] owns nix-darwin settings and imports [[system/keyboard|keyboard data]].
- [[devenv.nix]] imports [[.devenv-modules]] for root packages, tasks, formatting, and hooks.
- [[.nvim.lua]], [[.nvim]], and [[.pi]] contain tracked repository-local editor and Pi behavior.

## Root devenv setup

Root devenv behavior stays in tracked source rather than generated wrappers or shell-entry mutations.

[[.devenv-modules/treefmt.nix]] owns formatting exclusions for generated files, lock files, and upstream Lat resources; tracked modules remain normal formatted files.

[[.nvim.lua]] loads repository modules from [[.nvim/lua]] and LSP overrides from [[.nvim/lsp]]. Home Manager owns global Neovim behavior; root files add only repository behavior.

### Root language tooling

Editor diagnostics and commit hooks use matching engines where practical; exceptions below record only constraints that source configuration cannot explain.

[[.devenv-modules/git-hooks.nix]] owns commit checks. Manual hook runs use `prek`; `.pre-commit-config.yaml` is generated configuration, not the command to run.

Gitleaks uses the upstream hook entry and arguments together to preserve staged scanning and redaction; overriding only the entry can pair legacy subcommands with incompatible flags.

#### Lock file diagnostics

Generated lock files intentionally receive no editor or hook diagnostics.

Review lock changes through their owning update commands instead of adding formatters, schema checks, or filetype overrides.

#### Nix diagnostics

Nix uses nixd in Neovim, Statix through nvim-lint, and deadnix, Statix, and treefmt hooks.

Statix remains alongside nixd because it catches style checks that nixd misses; deadnix remains the hook gate for unused Nix code.

#### Markdown diagnostics

Markdown uses markdownlint in hooks and repository-local nvim-lint.

[[.nvim/lua/local_lint.lua|The local linter]] passes file paths instead of stdin so [[.markdownlintignore]] applies consistently.

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

Unknown files receive syntax checks only. [[devenv.yaml]] has an explicit schema mapping. The validator comes from the `otahontas-nixpkgs` devenv input.

#### Keyboard layout diagnostics

Apple keylayout data intentionally skips generic XML linting.

The generated file contains Apple-valid control references and CR line endings rejected by generic XML tools; see [[system-config#Keyboard layout file]].

#### Lua diagnostics

Lua uses EmmyLua in Neovim and hooks, with [[.emmyrc.json]] as the shared source of truth for LuaJIT, globals, ignored paths, and plugin runtime libraries.

`mini.nvim`'s `mini/base16.lua` stays ignored because EmmyLua 0.23.2 hangs while indexing it. Remove the ignore when upstream handles the module.

#### TypeScript diagnostics

TypeScript checks root and Home Manager Pi extensions against Pi's installed package types rather than local ambient declarations.

[[.devenv-modules/git-hooks.nix]] creates the `.devenv/pi-node-modules` symlink that exposes those types. [[home/flake.lock]] owns the Pi revision, while [[devenv.yaml]] follows `home/pi-nix`.

The hook runs the full project for staged TypeScript changes; Neovim uses the same [[tsconfig.json]] through `ts_ls`.

Path mappings use explicit `./` targets without `baseUrl`, which TypeScript 7 removed.

#### TOML diagnostics

TOML uses Taplo for formatting, editor diagnostics, and hook linting, with config-file-validator adding matched schema checks.

## Flake ownership

Home, system, and root devenv use unstable nixpkgs while each lock file owns its layer's inputs.

The Home Manager flake owns Pi and user-tool inputs. Root devenv imports `./home` only so `pi-nix` follows the Home Manager revision used by installed Pi extensions.

[[home/flake.nix]] uses upstream D-Bus unchanged: nixpkgs includes the Darwin session-bus fix. A global D-Bus override changes dependent package hashes, preventing use of their upstream cached binaries, including devenv.

`pi-nix` explicitly tracks upstream `master` because GitHub's commits API fails to resolve `HEAD` for this repository.

`pi-nix` retains its upstream nixpkgs lock: its build still requires `typescript-go`, removed from newer nixpkgs. Do not make it follow Home Manager's nixpkgs until upstream supports the rename.

## AGENTS.md pipeline

Pi concatenates global and repository `AGENTS.md` files, so each file contains only rules for its scope.

Home Manager links [[home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md]] and [[home/configs/pi-coding-agent/sources/APPEND_SYSTEM.md]] into global Pi state. Root [[AGENTS.md]] remains tracked and carries the upstream Lat workflow within its managed markers.

Global product UI copy rules distinguish task-relevant text from implementation commentary and redundant guidance; assistant response style remains separate.

Edit Home Manager-managed source files at their tracked paths, then run `devenv tasks run home:apply`. Refresh the managed Lat instructions and [[.pi/skills/lat-md/SKILL.md|authoring skill]] from upstream templates; record project-specific architecture and guidance in `lat.md/`.
