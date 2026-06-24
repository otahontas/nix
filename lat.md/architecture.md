# Architecture

Two-flake Nix setup for macOS: home-manager (user) + nix-darwin (system), sharing a devenv shell at the repo root.

## Repo layout

Top-level directories and key files.

```text
home/            home-manager flake — shells, CLI/GUI tools, catppuccin, pi-coding-agent
  configs/       per-tool directories, each with default.nix (49 configs)
system/          nix-darwin flake — macOS defaults, keyboard, firewall, nix daemon
  keyboard/      custom US International no-dead-keys layout
devenv.nix       repo-specific dev shell: tools, tasks, hooks, package wiring
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
- This devenv setup keeps repo-specific tools, tasks, and hooks in `devenv.nix`.
- Home Manager installs the global `lat.md` CLI from `home/configs/pi-coding-agent/lat-md.nix`, not from root `devenv.nix`.

## Root devenv setup

Root shell keeps repo-specific devenv behavior in `devenv.nix`, while tracked dotfiles stay editable normal files.

Treefmt config lives under the built-in `treefmt` key in `devenv.nix`; there are no manual wrappers or `repoDevenv.treefmt` overrides.

`.gitignore` and `.nvim.lua` are tracked normal files; edit them directly.

`.nvim.lua` owns root Neovim LSP setup, including the nixd Home Manager options that previously lived in `.nvim/lsp/nixd.lua`.

Root Pi files are tracked source: `.pi/extensions/lat.ts`, `.pi/extensions/post-edit-hook.ts`, and `.pi/skills/lat-md/SKILL.md`. Home Manager-owned Pi config lives under `home/configs/pi-coding-agent/`.

Treefmt excludes root `AGENTS.md` through global treefmt excludes; no typos hook or config remains in the repo.

### Root language tooling

Root language tooling covers repo filetypes that need editor or hook support.

- `devenv.nix` installs LSPs for Fish, JSON, Lua, YAML, and TOML, plus markdownlint for editor/hook linting and config-file-validator for schema hooks. JSON uses standalone `vscode-json-languageserver` because the extracted bundle fails at startup.
- `.nvim.lua` enables `nixd`, `bashls`, `fish_lsp`, `jsonls`, `emmylua_ls`, `yamlls`, and `taplo`; YAML includes the custom `yaml.github-action` filetype. It also owns repo-local nvim-lint and schema setup.
- Hooks check Nix with deadnix, Statix, and treefmt/nixfmt; shell scripts with ShellCheck's default severity and source following to match bashls more closely; Fish syntax with `fish --no-execute`; JSON syntax with `jq empty`; Lua with EmmyLua; Markdown with markdownlint using `.markdownlint.json` and `.markdownlintignore`; TOML with `taplo lint`; YAML with relaxed `yamllint`; and JSON/YAML/TOML schemas with config-file-validator.
- JSON keeps `jsonls` for editor syntax and schema diagnostics while hooks keep fast `jq empty` syntax checks and add config-file-validator for SchemaStore-backed schema checks.
- EmmyLua reads `.emmyrc.json` for LuaJIT, Neovim globals, ignored generated dirs, and Home Manager Neovim runtime libraries so plugin `require()` calls resolve in editor and hooks.
- `.emmyrc.json` ignores `mini.nvim`'s `mini/base16.lua` because EmmyLua 0.23.2 hangs when indexing that file.
- Neovim uses fish-lsp plus repo-local nvim-lint's Fish linter so saved Fish buffers include the same `fish --no-execute` parser check as hooks.
- Fish hooks stay on `fish --no-execute`: fish-lsp lacks a stable batch diagnostics CLI. Revisit when upstream `fish-lsp headless --diagnostics` lands so hooks can use fish-lsp diagnostics without a custom LSP wrapper.
- Repo-local nvim-lint runs markdownlint on saved Markdown file paths, keeping editor linting aligned with hook ignore behavior.
- Treefmt formats Lua with StyLua and TOML with Taplo in addition to existing nixfmt, shfmt, fish_indent, and Prettier; Prettier covers Markdown.

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

`.nvim.lua` defines `markdownlint_file` with file-path input rather than stdin. This lets markdownlint apply `.markdownlintignore`, matching hook behavior. The linter mapping stays repo-local in `.nvim.lua`; Home Manager only installs nvim-lint.

Alternatives considered:

- Keep Marksman: useful as a Markdown LSP, but not needed for current lint goals and not the hook engine.
- Use nvim-lint's default markdownlint stdin mode: simple, but `.markdownlintignore` did not apply like hooks.
- Configure nvim-lint globally: convenient, but repo-specific lint mappings belong in `.nvim.lua`.
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

The hook runs config-file-validator with SchemaStore enabled, no config discovery, and `devenv.yaml` mapped to `https://devenv.sh/devenv.schema.json`. Files with no matching schema pass syntax-only.

`devenv.nix` packages config-file-validator with `buildGoModule` from Boeing's v2.2.2 tag. The package keeps upstream tests enabled and patches one path-sensitive test assertion that matched Nix's `/build` path.

Neovim gets SchemaStore.nvim from Home Manager. `.nvim.lua` feeds SchemaStore schemas into `jsonls` and `yamlls`, then adds the same `devenv.yaml` schema as a YAML extra for root and nested paths.

Alternatives considered:

- Use v8r: rejected for hooks because unknown schema files are hard failures unless broad errors are ignored.
- Use check-jsonschema or jsonschema-cli directly: reliable for explicit schemas, but they need a custom SchemaStore matcher.
- Use yaml-schema-lint: close to yamlls, but YAML-only.
- Use Lintel: promising and fast, but too new and backed by its own moving catalog.

#### Lua diagnostics

Lua diagnostics use EmmyLua in Neovim and hooks so editor and commit checks share one semantic engine.

`.emmyrc.json` is the source of truth for Lua analysis. It sets LuaJIT, declares `vim` as a global, ignores generated directories, and loads these runtime libraries:

- `${workspaceFolder}/home/configs/neovim/nvim/lua` for tracked local modules.
- `{env:HOME}/.config/nvim/lua` for Home Manager-generated modules such as `treesitter_filetypes`.
- `{env:HOME}/.local/share/nvim/site/pack/hm/start` for Home Manager-installed plugin modules.

The hook calls `emmylua_check --config .emmyrc.json --warnings-as-errors` directly. Direct config keeps the hook simple and avoids generated config scripts.

`mini.nvim`'s `mini/base16.lua` is excluded because EmmyLua 0.23.2 hangs when indexing that file. Remove the ignore once EmmyLua handles that module.

Alternatives considered:

- Keep LuaLS in Neovim and Luacheck in hooks: fast, but split engines miss different problems and keep diagnostics mismatched.
- Use LuaLS CLI as hook: same editor engine, but workspace-oriented and poor for filename-based pre-commit hooks.
- Use Selene: fast and useful, but not editor parity and not plugin-runtime semantic checking.
- Generate hook config from a script: flexible, but too much moving code when `.emmyrc.json` can express the runtime paths.
- Generate any-stubs for required plugins: fast and quiet, but hides plugin API/type diagnostics.

#### TOML diagnostics

TOML diagnostics use Taplo for editor and hook linting, with config-file-validator as a supplemental schema layer.

`taplo` formats through treefmt, serves editor diagnostics through `taplo`, and checks hooks with `taplo lint`. Config-file-validator runs after that for SchemaStore-backed TOML schemas when a file has a match.

## Flakes

Both flakes pin `nixpkgs-unstable` independently. `home/` pulls extra inputs:

- **catppuccin / pi-catppuccin** — global theme (latte/blue) across terminal, editor, pi TUI
- **kanttiinit-cli** — personal CLI tool
- **pi-nix** — external flake at `github:lukasl-dev/pi.nix`; supplies the Pi package and Home Manager module
- **google-workspace-cli** — upstream Google Workspace CLI flake that supplies `gws`
- **brew-nix** — package overlay used by `mas` for Mac App Store installs
- **brew-api** — non-flake Homebrew API source followed by `brew-nix`

## AGENTS.md pipeline

Pi loads AGENTS.md from multiple locations (global + parent dirs + cwd), all concatenated. This repo uses both a tracked root `AGENTS.md` and a Home Manager-managed global source.

### Repository operating rules

Root `AGENTS.md` carries repo-local lat.md workflow and post-task checks.

- All commits can be pushed directly to default branch (`main`) in GitHub.
- Run `devenv tasks run home:apply` after changing Home Manager config.

### Global: home-manager

`home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md` → symlinked to `~/.pi/agent/AGENTS.md` by home-manager. Edit the source file, then `devenv tasks run home:apply`.

### Project: root devenv file

`devenv.nix` defines repo tools, tasks, and hooks without generating repo-local Pi files on shell entry. `AGENTS.md`, `.gitignore`, `.nvim.lua`, and root `.pi/` files stay tracked source.

### Key takeaway

Edit tracked repo files directly. For Home Manager symlinks like global AGENTS.md, modify `home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md`, then run `devenv tasks run home:apply`.

If `readlink` shows a nix store path, find the source (flake config, home-manager module, or root devenv setting) and change that instead.

## Secrets

LAT tooling gets `LAT_LLM_KEY` from the global Pi wrapper, keeping the value outside git and avoiding per-repo secret setup.

- The Pi wrapper in `home/configs/pi-coding-agent/default.nix` reads pass entry `api/lat-md` directly into `LAT_LLM_KEY`.
- Root `devenv.nix` no longer installs the `lat.md` CLI; `home/configs/pi-coding-agent/default.nix` calls `lat-md.nix` and exposes the result globally.

## Tasks

Defined in `devenv.nix`, run with `devenv tasks run <task>`:

- `home:apply` — home-manager switch
- `system:apply` — darwin-rebuild switch (requires sudo)
- `nix:format` — treefmt formatters
- `nix:update` — update home/system lockfiles + devenv, apply home-manager, then run `pi update --extensions`
