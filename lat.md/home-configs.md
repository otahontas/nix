# Home configs

Home Manager imports each `home/configs/*/default.nix`; helper files require an explicit import or read from their owning config.

## Patterns

Home configs prefer declarative ownership and keep tool-specific behavior with its package.

- Use Home Manager `programs` or `services` before adding raw packages.
- Remove tool-specific flake inputs, special arguments, and unused entries in Home Manager and devenv locks with their owning config.
- Install and update GUI apps outside Nix in `/Applications`; Home Manager app copying and linking stay disabled.
- Keep selected app settings in Home Manager without installing their binaries; see [[system-config#Manual applications]].
- Use `launchd.agents` for startup jobs and out-of-store symlinks only for intentionally mutable paths.
- Music folder redirects cover only `Audio Music Apps` and `MainStage`, targeting their namesakes under `~/Documents`; other music folders remain unmanaged.
- Keep machine-local artifacts, including Obsidian's `.obsidian` settings, in global Git ignores rather than every repository.

## Fish integration

Each tool owns its Fish integration in its config directory.

Aliases use `shellAliases` in their tool's config: Git owns worktree aliases and Bat owns `cat`. Interactive setup and function bodies live in external files; completions use `fish/conf.d/` entries to avoid replacing upstream completions.

Devenv's custom PWD hook still activates shells with `--no-reload`, retained after a terminal ABI failure. Devenv 2.4.0 provides native Fish hooks and dynamic task completion; the existing custom integration remains installed.

## Shell scripts

Scripts live beside their owning config and are loaded with `builtins.readFile` plus `writeShellScriptBin`.

Related commands may dispatch from `basename "$0"`; filename-sensitive scripts use arrays and null delimiters.

## Notable configs

Only ownership boundaries and non-obvious conflicts are documented here; package inventories belong to source.

- **GPG/SSH** — gpg-agent owns SSH authentication and Git signing through the YubiKey; SSH points `IdentityAgent` at that agent.
- **Ghostty** — Home Manager owns settings and links its XDG config into macOS Application Support, but leaves installation manual with `package = null`; title and bell effects surface Pi notifications.
- **Obsidian** — app, updates, and vaults stay user-managed; Home Manager no longer merges its application settings.
- **Syncthing** — native Home Manager service installs the CLI and macOS launchd agent; devices and folders stay user-managed and survive service restarts. Web UI/API stays on loopback; no desktop app is installed.
- **IINA** — manually installed app; `duti` runs only from the activation store path after `writeBoundary` to apply media associations.
- **fzf** — its `Ctrl-R` binding stays disabled because atuin owns history search.
- **Git worktrees** — Git owns local-branch helpers, shell aliases, and Bash/Fish wrappers. Helpers assume dash-only branch and path names and use standard worktree creation without encryption-specific filters or metadata links; wrappers only change directories and provide completion.
- **GitHub CLI** — `gh` and its `web = "repo view --web"` alias remain; custom repository URL, workflow-run, and PR helpers, Neovim permalinks, PR worktrees, and PR-derived release messaging are removed.
- **Password store** — `pass-otp` and `pass-genphrase` remain installed; `pass-update` is removed.
- **Neovim** — Home Manager owns plugins and global save hooks; root `.nvim.lua` owns repository-only LSP and lint behavior documented in [[architecture#Root devenv setup]].
- **Pi coding agent** — [[pi-coding-agent]] owns wrapper, extension, skill, prompt, and MCP behavior.

## Neovim password buffers

Neovim identifies `pass edit` temporary files as `pass`. Both Blink and Copilot block that filetype; Blink's gate alone cannot block Copilot's independent inline suggestions.

## Neovim todo.txt sorting

`:Sort` places unfinished tasks before completed tasks. Each group retains due date → threshold date → priority → area → natural alphabetical order, excluding priority from alphabetical comparison.

Completion follows the parsed leading `x`, including indented entries and entries without completion dates. Missing dates, priorities, and areas still sort last within each completion group.
