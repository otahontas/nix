# Home configs

One directory per tool under `home/configs/`, each with `default.nix`. Home-manager auto-imports them all.

## Shell scripts

Shell scripts live in `scripts/` subdirectories next to their `default.nix`. The nix files use `builtins.readFile ./scripts/<name>.sh` with `writeShellScriptBin`. This keeps scripts lintable and formattable.

Configs with extracted scripts:

- `fd/` — `find-and-prune`
- `fish/` — `listening`, `nukeport`, `trash-empty`
- `git/` — `format-duration`, `gh-*` helpers, `git-worktree-prune`
- `neovim/` — `todo_path`, `daily_path`, `todo`, `daily`
- `pi-coding-agent/` — `pi` wrapper (uses `replaceVars` for nix store paths)
- `qpdf/` — `combine-pdfs-in-folder`
- `sleep/` — `disable-sleep`, `enable-sleep`
- `yubikey-manager/` — `yk-status`

## pi-coding-agent

Builds pi and lat-md from npm, wraps `pi` with PATH and API keys.

Extensions, skills, agents, prompts, and models symlink from the config directory to `~/.pi/agent/`.
