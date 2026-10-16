# Home configs

[[home/flake.nix]] imports each tool's `default.nix` under [[home/configs]]; helper files require an explicit import or read from their owning config.

## Patterns

Home configs prefer declarative ownership and keep tool-specific behavior with its package.

- Use Home Manager `programs` or `services` before adding raw packages.
- Remove tool-specific flake inputs, special arguments, and unused entries in Home Manager and devenv locks with their owning config.
- Install and update GUI apps outside Nix in `/Applications`; Home Manager app copying and linking stay disabled.
- Keep selected app settings in Home Manager without installing their binaries; see [[system-config#Manual applications]].
- Use `launchd.agents` for startup jobs and out-of-store symlinks only for intentionally mutable paths.
- [[home/configs/symlinks/default.nix|Music folder redirects]] cover only `Audio Music Apps` and `MainStage`, targeting their namesakes under `~/Documents`; other music folders remain unmanaged.
- Keep machine-local artifacts, including Obsidian's `.obsidian` settings, in global Git ignores rather than every repository.

## Fish integration

Each tool owns its Fish integration in its config directory.

Aliases use `shellAliases` in their tool's config: Git owns worktree aliases and Bat owns `cat`. Interactive setup and function bodies live in external files; completions use `fish/conf.d/` entries to avoid replacing upstream completions.

[[home/configs/devenv/devenv.fish|Devenv's custom PWD hook]] activates shells with `--no-reload` because of a terminal ABI failure. [[home/configs/devenv/default.nix]] owns that integration and [[home/configs/devenv/devenv-tasks-run.fish|task completion]].

## Shell scripts

Scripts live beside their owning config and are loaded with `builtins.readFile` plus `writeShellScriptBin`.

Related commands may dispatch from `basename "$0"`; filename-sensitive scripts use arrays and null delimiters.

## Notable configs

Only ownership boundaries and non-obvious conflicts are documented here; package inventories belong to source.

- **GPG/SSH** — [[home/configs/gpg/default.nix]] assigns SSH authentication and Git signing to gpg-agent through the YubiKey; [[home/configs/ssh/default.nix]] points SSH at that agent.
- **Ghostty** — [[home/configs/ghostty/default.nix]] owns settings and links its XDG config into macOS Application Support, but leaves installation manual; title and bell effects surface Pi notifications.
- **Obsidian** — app, settings, updates, and vaults stay user-managed.
- **Syncthing** — [[home/configs/syncthing/default.nix]] enables the native Home Manager CLI and macOS launchd agent; devices and folders stay user-managed and survive service restarts. Web UI/API stays on loopback; no desktop app is installed.
- **IINA** — [[home/configs/iina/default.nix]] applies media associations through the activation store path after `writeBoundary`; app installation remains manual.
- **Atuin** — [[home/configs/atuin/default.nix]] disables build tests only for version 18.23.0 because `filtered_commands_leave_no_captured_output` times out on macOS. Other versions use the unmodified upstream package automatically. A cached binary appearing for 18.23.0 does not deactivate the override.
- **fzf** — [[home/configs/fzf/default.nix]] leaves history search to [[home/configs/atuin/default.nix|atuin]] instead of claiming its keybinding.
- **Git worktrees** — [[home/configs/git/default.nix]] owns local-branch helpers, shell aliases, and Bash/Fish wrappers. [[home/configs/git/scripts/git-worktree-helper.sh|Helpers]] assume dash-only branch and path names and use standard worktree creation; wrappers only change directories and provide completion.
- **Neovim** — [[home/configs/neovim/default.nix]] owns plugins and global save hooks; [[.nvim.lua]] owns repository-only LSP and lint behavior documented in [[architecture#Root devenv setup]].
- **Pi coding agent** — [[pi-coding-agent]] owns wrapper, extension, skill, prompt, and MCP behavior.

## Neovim password buffers

[[home/configs/neovim/nvim/filetype.lua]] identifies `pass edit` temporary files as `pass`. Both [[home/configs/neovim/nvim/plugin/packages/blink.lua|Blink]] and [[home/configs/neovim/nvim/plugin/packages/copilot.lua|Copilot]] block that filetype; Blink's gate alone cannot block Copilot's independent inline suggestions.

## Neovim todo.txt sorting

[[home/configs/neovim/nvim/after/ftplugin/todotxt.lua]] defines `:Sort` to place unfinished tasks before completed tasks. Each group retains due date → threshold date → priority → area → natural alphabetical order, excluding priority from alphabetical comparison.

Completion follows the parsed leading `x`, including indented entries and entries without completion dates. Missing dates, priorities, and areas still sort last within each completion group.
