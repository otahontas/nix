# Home configs

Home Manager imports each `home/configs/*/default.nix`; helper files require an explicit import or read from their owning config.

## Patterns

Home configs prefer declarative ownership and keep tool-specific behavior with its package.

- Use Home Manager `programs` or `services` before adding raw packages.
- Install suitable Darwin app bundles through Home Manager or brew-nix; copied apps remain visible to Spotlight.
- Treat brew-nix casks in `home.packages` as Nix-owned, not manual installs.
- Keep vendor-managed system software under [[system-config#Manual applications]].
- Use `launchd.agents` for startup jobs and out-of-store symlinks only for intentionally mutable paths.
- Keep machine-local artifacts in global Git ignores rather than every repository.

## Fish integration

Each tool owns its Fish integration in its config directory.

Aliases use `shellAliases`; interactive setup and function bodies live in external files; completions use `fish/conf.d/` entries to avoid replacing upstream completions. Devenv activation belongs to the devenv config.

## Shell scripts

Scripts live beside their owning config and are loaded with `builtins.readFile` plus `writeShellScriptBin`.

Related commands may dispatch from `basename "$0"`; filename-sensitive scripts use arrays and null delimiters.

## Notable configs

Only ownership boundaries and non-obvious conflicts are documented here; package inventories belong to source.

- **GPG/SSH** — gpg-agent owns SSH authentication and Git signing through the YubiKey; SSH points `IdentityAgent` at that agent.
- **Ghostty** — uses the Darwin package and links its XDG config into macOS Application Support; title and bell effects surface Pi notifications.
- **IINA** — `duti` runs only from the activation store path when applying media associations.
- **Discord** — brew-nix owns the signed app, so host self-updates stay disabled.
- **fzf** — its `Ctrl-R` binding stays disabled because atuin owns history search.
- **Git worktrees** — shared helpers assume dash-only branch and path names; Bash and Fish wrappers only change directories and provide completion.
- **Neovim** — Home Manager owns plugins and global save hooks; root `.nvim.lua` owns repository-only LSP and lint behavior documented in [[architecture#Root devenv setup]].
- **Pi coding agent** — [[pi-coding-agent]] owns wrapper, extension, skill, prompt, and MCP behavior.
