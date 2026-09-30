# Home configs

Home Manager imports each `home/configs/*/default.nix`; helper files require an explicit import or read from their owning config.

## Patterns

Home configs prefer declarative ownership and keep tool-specific behavior with its package.

- Use Home Manager `programs` or `services` before adding raw packages.
- Install and update GUI apps outside Nix in `/Applications`; Home Manager app copying and linking stay disabled.
- Keep selected app settings in Home Manager without installing their binaries; see [[system-config#Manual applications]].
- Use `launchd.agents` for startup jobs and out-of-store symlinks only for intentionally mutable paths.
- Music folder redirects cover only `Audio Music Apps` and `MainStage`, targeting their namesakes under `~/Documents`; other music folders remain unmanaged.
- Keep machine-local artifacts, including Obsidian's `.obsidian` settings, in global Git ignores rather than every repository.

## Fish integration

Each tool owns its Fish integration in its config directory.

Aliases use `shellAliases`; interactive setup and function bodies live in external files; completions use `fish/conf.d/` entries to avoid replacing upstream completions. Devenv activation belongs to the devenv config.

Devenv auto-activation uses `--no-reload` because packaged devenv 2.3.1 and libghostty-vt have incompatible terminal ABIs. Hot-reload stays disabled until a compatible package build is verified.

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
- **Git worktrees** — shared helpers assume dash-only branch and path names; Bash and Fish wrappers only change directories and provide completion.
- **Neovim** — Home Manager owns plugins and global save hooks; root `.nvim.lua` owns repository-only LSP and lint behavior documented in [[architecture#Root devenv setup]].
- **Pi coding agent** — [[pi-coding-agent]] owns wrapper, extension, skill, prompt, and MCP behavior.

## Neovim password buffers

Neovim identifies `pass edit` temporary files as `pass`. Both Blink and Copilot block that filetype; Blink's gate alone cannot block Copilot's independent inline suggestions.

## Neovim todo.txt sorting

`:Sort` places unfinished tasks before completed tasks. Each group retains due date → threshold date → priority → area → natural alphabetical order, excluding priority from alphabetical comparison.

Completion follows the parsed leading `x`, including indented entries and entries without completion dates. Missing dates, priorities, and areas still sort last within each completion group.
