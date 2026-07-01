# Architecture

Two-flake Nix setup for macOS: home-manager (user) + nix-darwin (system), sharing a devenv shell at the repo root.

## Repo layout

Top-level directories and key files.

```text
home/            home-manager flake — shells, CLI/GUI tools, catppuccin, pi-coding-agent
  configs/       per-tool directories, each with default.nix (49 configs)
system/          nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
  keyboard/      custom US International no-dead-keys layout
devenv.nix       root devenv entrypoint importing tracked modules
.devenv-modules/ repo-specific dev shell modules: tools, tasks, hooks, package wiring
.pi/            repo-local lat tool extension and skill source
devenv.yaml      declares root devenv inputs
lat.md/          this documentation
```

## Devenv

This repo uses devenv for reproducible development environments.

- Use `devenv shell -- <cmd>` to run commands in the dev environment.
- Use `devenv tasks run <task>` to run defined tasks.
- Use `devenv up` for process services.
- Always use devenv to install tools and services or to define tasks.
- This devenv setup keeps repo-specific tools, tasks, and hooks in `devenv.nix` plus tracked `.devenv-modules/` files.
- Home Manager installs the global `lat.md` CLI from `home/configs/pi-coding-agent/lat-md.nix`, not from root `devenv.nix`.

## Root devenv setup

Root shell keeps repo-specific devenv behavior in `devenv.nix` and tracked `.devenv-modules/`, while tracked dotfiles stay editable normal files.

Treefmt config lives under the built-in `treefmt` key in `.devenv-modules/treefmt.nix`; there are no manual wrappers or `repoDevenv.treefmt` overrides.

`.gitignore` ignores only the generated `.devenv/` directory; `.devenv-modules/` and `.nvim.lua` are tracked normal files and are edited directly.

`.nvim.lua` adds the repo `.nvim/` runtimepath and loads repo-local modules from `.nvim/lua/local_lint.lua` and `.nvim/lua/local_lsp.lua`; LSP overrides live under `.nvim/lsp/`.

Root Pi files are tracked source: `.pi/extensions/lat.ts`, `.pi/extensions/post-edit-hook.ts`, and `.pi/skills/lat-md/SKILL.md`. Home Manager-owned Pi config lives under `home/configs/pi-coding-agent/`.

`devenv.nix` imports `.devenv-modules/default.nix`, which fans out to shared helpers, packages, treefmt, languages, tasks, and hooks.

Treefmt excludes generated `.devenv/` and root `AGENTS.md`; tracked `.devenv-modules/` stays formatted, and no typos hook or config remains in the repo.

### Root language tooling

Root language tooling covers repo filetypes that need editor or hook support.

- `devenv.nix` imports `.devenv-modules/`; `packages.nix` installs LSPs for Fish, JSON, Lua, TypeScript, YAML, and TOML, plus markdownlint for editor/hook linting, while `git-hooks.nix` takes config-file-validator from the `otahontas-nixpkgs` input for schema hooks. JSON uses standalone `vscode-json-languageserver` because the extracted bundle fails at startup.
- `.nvim.lua` adds `.nvim/` to `runtimepath` and loads repo-local modules; `.nvim/lua/local_lsp.lua` enables `nixd`, `bashls`, `fish_lsp`, `jsonls`, `emmylua_ls`, `yamlls`, `ts_ls`, and `taplo`; custom LSP config files live in `.nvim/lsp/`, and `.nvim/lua/local_lint.lua` defines repo-only nvim-lint behavior.
- Hooks check Nix with deadnix, Statix, and treefmt/nixfmt; shell scripts with ShellCheck's default severity and source following to match bashls more closely; Fish syntax with `fish --no-execute`; JSON syntax with `jq empty`; Lua with EmmyLua; TypeScript with `tsc --noEmit`; Markdown with markdownlint using `.markdownlint.json` and `.markdownlintignore`; TOML with `taplo lint`; YAML with relaxed `yamllint`; and JSON/YAML/TOML schemas with config-file-validator.
- Manual hook runs use `prek`, never `pre-commit`. `.pre-commit-config.yaml` is generated hook config, not the CLI to invoke.
- JSON keeps `jsonls` for editor syntax and schema diagnostics while hooks keep fast `jq empty` syntax checks and add config-file-validator for SchemaStore-backed schema checks.
- Lock files are generated state: never add lint hooks, formatters, schema checks, filetype overrides, nvim-lint mappings, or LSP setup for them.
- EmmyLua reads `.emmyrc.json` for LuaJIT, Neovim globals, ignored generated dirs, repo `.nvim/lua`, and Home Manager Neovim runtime libraries so plugin `require()` calls resolve in editor and hooks.
- `.emmyrc.json` ignores `mini.nvim`'s `mini/base16.lua` because EmmyLua 0.23.2 hangs when indexing that file.
- Neovim uses fish-lsp plus repo-local nvim-lint's Fish linter so saved Fish buffers include the same `fish --no-execute` parser check as hooks.
- Fish hooks stay on `fish --no-execute`: fish-lsp lacks a stable batch diagnostics CLI. Revisit when upstream `fish-lsp headless --diagnostics` lands so hooks can use fish-lsp diagnostics without a custom LSP wrapper.
- Repo-local nvim-lint runs markdownlint on saved Markdown file paths, keeping editor linting aligned with hook ignore behavior.
- Treefmt formats Lua with StyLua and TOML with Taplo in addition to existing nixfmt, shfmt, fish_indent, and Prettier; Prettier covers Markdown.

#### Lock file diagnostics

Lock files are generated dependency state and intentionally have no editor or hook diagnostics.

Do not add lint hooks, formatters, schema validation, filetype overrides, nvim-lint mappings, or LSP setup for lock files such as `devenv.lock`, `flake.lock`, `*.lock`, or `*.lockb`. Review generated lockfile changes through their owning update commands instead.

#### Nix diagnostics

Nix diagnostics use nixd in Neovim plus deadnix, Statix, and treefmt hooks because no single CLI matches the editor's semantic analysis.

`nixd` reports syntax errors, undefined variables, and unused bindings that overlap deadnix. Statix catches style lints such as empty `let in` and manual `inherit` patterns that nixd does not report, so repo-local nvim-lint runs Statix on saved Nix buffers.

Hooks keep deadnix with `--fail`, run Statix repo-wide with `.devenv` ignored, and use treefmt with nixfmt for formatting. Editor Statix is per-buffer; manually opened generated files may still show diagnostics.

Alternatives considered:

- Use only nixd: strong editor diagnostics, but misses Statix style lints that hooks enforce.
- Add deadnix to nvim-lint: redundant for tested unused let and lambda diagnostics because nixd reports them.
- Run nvim-lint's `nix` parser linter: useful for syntax, but nixd already reports parser diagnostics.

#### Markdown diagnostics

Markdown diagnostics use markdownlint in hooks and repo-local nvim-lint so saved buffers respect the same config and ignore files.

Home Manager's `nvim-lint.lua` defines the global save autocmd. `.nvim/lua/local_lint.lua` defines `markdownlint_file` with file-path input and maps Markdown to it so `.markdownlintignore` matches hook behavior.

Alternatives considered:

- Keep Marksman: useful as a Markdown LSP, but not needed for current lint goals and not the hook engine.
- Use nvim-lint's default markdownlint stdin mode: simple, but `.markdownlintignore` did not apply like hooks.
- Configure repo linter mappings globally: convenient, but repo-specific linter selection belongs in the repo runtime.
- Keep the typos hook: broader spelling checks, but too noisy for this repo's language-tooling alignment.

#### Bash diagnostics

Bash diagnostics use bashls in Neovim and ShellCheck hooks with matching severity and source-following behavior.

BashLS shells out to ShellCheck with default severity, external source following, and a source path near the current file. The hook mirrors that by running ShellCheck on file paths with `--external-sources` and `--source-path` set to the file directory.

Alternatives considered:

- Keep `--severity=warning`: stricter hook output, but it disagreed with BashLS by hiding info-level diagnostics.
- Omit source following: simpler, but sourced files produced different diagnostics between editor and hooks.
- Replace BashLS with nvim-lint: unnecessary because BashLS already exposes ShellCheck diagnostics.

#### Fish diagnostics

Fish diagnostics keep fish-lsp in Neovim and add the same parser check as hooks through repo-local nvim-lint.

The hook uses `fish --no-execute` because it is stable, fast, and filename-based. `fish_lsp` remains enabled because it adds useful editor diagnostics, but upstream lacks a stable batch diagnostics CLI for hooks.

Alternatives considered:

- Use fish-lsp experimental diagnostics only: it crashed on current test cases.
- Write a custom LSP wrapper for hooks: possible, but too fragile while upstream plans `fish-lsp headless --diagnostics`.
- Use only `fish --no-execute` in the editor: would miss fish-lsp's extra static diagnostics.

#### JSON diagnostics

JSON diagnostics use jsonls in Neovim, `jq empty` for fast hook syntax checks, and config-file-validator for SchemaStore-backed schema checks.

`jsonls` uses standalone `vscode-json-languageserver` because the extracted bundle failed at startup under Node. Hooks keep `jq empty` because it is fast and catches invalid JSON before the broader schema hook runs.

Alternatives considered:

- Use `vscode-langservers-extracted`: rejected because its JSON server wrapper failed at startup.
- Run a Node wrapper around `vscode-json-languageservice`: closest engine match, but too much code for current syntax-only hook needs.
- Use `check-jsonschema`: useful for explicit schemas, but slower and not automatic for SchemaStore filename matches.
- Use `jsonschema-cli`: fast and packaged in nixpkgs, but still needs custom SchemaStore fileMatch resolution.

#### Config schema diagnostics

Config schema diagnostics use config-file-validator in hooks and SchemaStore.nvim in Neovim so known JSON/YAML/TOML files get schema checks without forcing schemas on unknown files.

`git-hooks.nix` calls the packaged validator through hook `entry` and `args`, with SchemaStore enabled, config discovery disabled, and `devenv.yaml` mapped to `https://devenv.sh/devenv.schema.json`. Files with no matching schema pass syntax-only.

`config-file-validator` comes from the `otahontas-nixpkgs` devenv input (`github:otahontas/nixpkgs`) instead of a local `buildGoModule` package.

Neovim gets SchemaStore.nvim from Home Manager. `.nvim/lsp/jsonls.lua` and `.nvim/lsp/yamlls.lua` feed SchemaStore schemas into JSON and YAML language servers, then YAML adds the same `devenv.yaml` schema for root and nested paths.

Alternatives considered:

- Use v8r: rejected for hooks because unknown schema files are hard failures unless broad errors are ignored.
- Use check-jsonschema or jsonschema-cli directly: reliable for explicit schemas, but they need a custom SchemaStore matcher.
- Use yaml-schema-lint: close to yamlls, but YAML-only.
- Use Lintel: promising and fast, but too new and backed by its own moving catalog.

#### Keyboard layout diagnostics

Keyboard layout diagnostics intentionally skip generic XML linting for Apple `.keylayout` files.

The custom keyboard layout contains Apple-valid control character references and CR-only line endings. Generic XML tools such as `xmllint` and `plutil` reject the file for reasons unrelated to the macOS keyboard layout contract.

Alternatives considered:

- Use `xmllint`: rejected because XML 1.0 validation rejects Apple control character references such as `&#x0010;`.
- Use `plutil`: rejected because keylayout files are not property lists and use a `<keyboard>` root.
- Add custom keylayout linting: not worth maintaining for a generated, rarely edited layout file.

#### Lua diagnostics

Lua diagnostics use EmmyLua in Neovim and hooks so editor and commit checks share one semantic engine.

`.emmyrc.json` is the source of truth for Lua analysis. It sets LuaJIT, declares `vim` as a global, ignores generated directories, and loads these runtime libraries:

- `${workspaceFolder}/home/configs/neovim/nvim/lua` for tracked Home Manager modules.
- `${workspaceFolder}/.nvim/lua` for repo-local Neovim modules.
- `{env:HOME}/.config/nvim/lua` for Home Manager-generated modules such as `treesitter_filetypes`.
- `{env:HOME}/.local/share/nvim/site/pack/hm/start` for Home Manager-installed plugin modules.

The hook calls `emmylua_check --config .emmyrc.json --warnings-as-errors` directly. Direct config keeps the hook simple and avoids generated config scripts.

Lua code prefers explicit nil/type checks or small helpers over local casts. `any` annotations stay only where plugin runtime types reject valid configs.

`mini.nvim`'s `mini/base16.lua` is excluded because EmmyLua 0.23.2 hangs when indexing that file. Remove the ignore once EmmyLua handles that module.

Alternatives considered:

- Keep LuaLS in Neovim and Luacheck in hooks: fast, but split engines miss different problems and keep diagnostics mismatched.
- Use LuaLS CLI as hook: same editor engine, but workspace-oriented and poor for filename-based Git hooks.
- Use Selene: fast and useful, but not editor parity and not plugin-runtime semantic checking.
- Generate hook config from a script: flexible, but too much moving code when `.emmyrc.json` can express the runtime paths.
- Generate any-stubs for required plugins: fast and quiet, but hides plugin API/type diagnostics.

#### TypeScript diagnostics

TypeScript diagnostics typecheck local Pi extension files against Pi's real package types.

`tsconfig.json` includes root `.pi/extensions/**/*.ts` and Home Manager-owned `home/configs/pi-coding-agent/extensions/**/*.ts`. The compiler uses `NodeNext`, strict mode, no emit, and Node types from Pi's package closure.

`.devenv-modules/packages.nix` adds TypeScript and `typescript-language-server`. `.devenv-modules/git-hooks.nix` keeps Pi's package `node_modules` available as `.devenv/pi-node-modules` for shell/editor use and refreshes that symlink before the TypeScript hook runs, so no Nix store path is committed.

`home/flake.lock` owns the Pi package revision. `devenv.yaml` imports the `home` flake as a path input and makes root `pi-nix` follow `home/pi-nix`, so typechecks follow the same Pi package Home Manager installs.

The TypeScript hook triggers only during the Git pre-commit stage on TypeScript files and runs the full Pi extension project with `pass_filenames = false` because `tsc -p` owns file selection. Neovim enables `ts_ls`, so saved extension files and hooks read the same project config.

Alternatives considered:

- Use checked-in ambient declarations: rejected because local stubs could hide Pi API drift.
- Hardcode the Pi package store path in `tsconfig.json`: rejected because store paths change across updates.
- Add a devenv typecheck task: rejected because the Git hook is the required gate.
- Add ESLint or Biome first: deferred because API type drift is the current risk, not style.

#### TOML diagnostics

TOML diagnostics use Taplo for editor and hook linting, with config-file-validator as a supplemental schema layer.

`taplo` formats through treefmt, serves editor diagnostics through `taplo`, and checks hooks with `taplo lint`. Config-file-validator runs after that for SchemaStore-backed TOML schemas when a file has a match.

## Flakes

Home, system, and root devenv use `github:NixOS/nixpkgs/nixpkgs-unstable` as their primary `nixpkgs` source. `home/` pulls extra inputs:

- **nixpkgs-mise-fixed** — temporary Home Manager input pinned to NixOS/nixpkgs#534965's merge commit so `mise` avoids the Darwin setuid test failure; remove once primary nixpkgs includes that fix
- **catppuccin / pi-catppuccin** — global theme (latte/blue) across terminal, editor, pi TUI
- **kanttiinit-cli** — personal CLI tool
- **pi-nix** — external flake at `github:lukasl-dev/pi.nix`; supplies the Pi package and Home Manager module
- **google-workspace-cli** — upstream Google Workspace CLI flake that supplies `gws`
- **brew-nix** — package overlay used by `mas` for Mac App Store installs
- **brew-api** — non-flake Homebrew API source followed by `brew-nix`

Root `devenv.yaml` also pulls `github:otahontas/nixpkgs` as `otahontas-nixpkgs` so hooks can install packaged personal tools without local derivations. It imports `./home` only so root `pi-nix` can follow `home/pi-nix` for Pi extension typechecks.

## AGENTS.md pipeline

Pi loads AGENTS.md from multiple locations (global + parent dirs + cwd), all concatenated. This repo uses both a tracked root `AGENTS.md` and a Home Manager-managed global source.

### Repository operating rules

Root `AGENTS.md` carries repo-local lat.md workflow and post-task checks.

- All commits can be pushed directly to default branch (`main`) in GitHub.
- Run `devenv tasks run home:apply` after changing Home Manager config.

### Global: home-manager

`home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md` → symlinked to `~/.pi/agent/AGENTS.md` by home-manager. Edit the source file, then `devenv tasks run home:apply`.

### Project: root devenv file

`devenv.nix` imports tracked `.devenv-modules/` files that define repo tools, tasks, and hooks without generating repo-local Pi files on shell entry. `AGENTS.md`, `.gitignore`, `.nvim.lua`, `.nvim/`, and root `.pi/` files stay tracked source.

### Key takeaway

Edit tracked repo files directly. For Home Manager symlinks like global AGENTS.md, modify `home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md`, then run `devenv tasks run home:apply`.

If `readlink` shows a nix store path, find the source (flake config, home-manager module, or root devenv setting) and change that instead.

## Secrets

LAT tooling gets `LAT_LLM_KEY` from the global Pi wrapper, keeping the value outside git and avoiding per-repo secret setup.

- The Pi wrapper in `home/configs/pi-coding-agent/default.nix` reads pass entry `api/lat-md` directly into `LAT_LLM_KEY`.
- Root `devenv.nix` no longer installs the `lat.md` CLI; `home/configs/pi-coding-agent/default.nix` calls `lat-md.nix` and exposes the result globally.

## Tasks

Defined in `.devenv-modules/tasks.nix`, imported by `devenv.nix`; run with `devenv tasks run <task>`:

- `home:apply` — home-manager switch
- `system:apply` — darwin-rebuild switch (requires sudo)
- `nix:format` — treefmt formatters
- `nix:update` — update home/system lockfiles + devenv, apply home-manager, then run `pi update --extensions`

For a Pi-only package update, run `nix flake update pi-nix --flake ./home`, then `devenv update home`. Root `pi-nix` follows `home/pi-nix`, so `home/flake.lock` is the source of truth and `devenv.lock` records the followed revision.
