# Home configs

One directory per tool under `home/configs/`, each with `default.nix`. Home-manager auto-imports them all.

## Shell scripts

Shell scripts live in `scripts/` subdirectories next to their `default.nix`. The nix files use `builtins.readFile ./scripts/<name>.sh` with `writeShellScriptBin`. This keeps scripts lintable and formattable.

Related scripts are grouped into single files using `basename "$0"` dispatch — each `writeShellScriptBin` creates a binary whose name determines which function runs.

Configs with extracted scripts:

- `fd/` — `find-and-prune`
- `git/` — `gh.sh` (all `gh-*` helpers), `git-extras.sh` (`format-duration`, `git-worktree-prune`)
- `neovim/` — `todo.sh` (`todo_path`, `todo`), `daily.sh` (`daily_path`, `daily`)
- `qpdf/` — `combine-pdfs-in-folder`
- `sleep/` — `sleep.sh` (`disable-sleep`, `enable-sleep`)
- `utils/` — `utils.sh` (`listening`, `nukeport`, `trash-empty`)
- `yubikey-manager/` — `yk-status`

## pi-coding-agent

Builds pi and lat-md from npm, wraps `pi` with PATH and API keys.

Extensions, skills, agents, prompts, and models symlink from the config directory to `~/.pi/agent/`.
