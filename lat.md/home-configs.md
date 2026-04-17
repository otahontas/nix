# Home configs

One directory per tool under `home/configs/` (43 configs), each with `default.nix`. Auto-imported by `lib.filesystem.listFilesRecursive` — add a directory, it appears.

Apply with `devenv tasks run home:apply`. Stage new files before applying; don't commit unless asked.

## Patterns

Conventions for writing home-manager configs.

- **Home manager first** — use `programs`/`services`, fallback to `pkgs`
- **Session variables** for paths and environment config
- **GUI apps** — prefer home-manager when nixpkgs has darwin `.app` bundle; `targets.darwin.copyApps.enable = true` for Spotlight
- **LaunchAgents** via `launchd.agents` for auto-start
- **Out-of-store symlinks** via `config.lib.file.mkOutOfStoreSymlink` (see `symlinks/`)
- **Mac App Store** apps via `mas` activation script (pending native nix-darwin module)

## Fish integration

Each tool owns its fish integration in its own config directory:

- Aliases → `shellAliases`
- Interactive init → `builtins.readFile` from external file, never inline
- Completions → `xdg.configFile."fish/conf.d/<tool>.fish".text` (avoids overriding upstream)
- Functions → always with `description` and `body` from external file

## Shell scripts

Scripts live in `scripts/` subdirectories next to `default.nix`, loaded via `builtins.readFile` + `writeShellScriptBin`. Related scripts grouped into single files using `basename "$0"` dispatch — binary name determines which function runs.

Configs with scripts: `fd`, `git`, `neovim`, `pi-coding-agent`, `qpdf`, `sleep`, `utils`, `yubikey-manager`.

## Notable configs

Configs worth documenting beyond a table row.

- **GPG/SSH** (`gpg/`) — YubiKey-based: gpg-agent with SSH support, GPG signing for git, `pinentry_mac` for GUI prompts
- **ghostty** — uses `ghostty-bin` (Linux-only `ghostty` lacks darwin support); symlinks config from XDG to Application Support where macOS Ghostty looks for it
- **pi-coding-agent** — builds pi from npm, wraps `pi` with PATH and API keys; extensions/skills/agents/prompts/models symlink to `~/.pi/agent/`
- **password-store** — pass with GPG integration
- **neovim** — `.nvim.lua` config with LSPs for Nix, shell, Lua; custom spell file
- **git** — GPG-signed commits, allowed_signers, gh CLI helpers, worktree scripts

### pi-coding-agent structure

Directory layout of `home/configs/pi-coding-agent/`.

- `default.nix` — main config, auto-discovers and symlinks everything below
- `sources/GLOBAL_AGENTS.md` — source for global `~/.pi/agent/AGENTS.md` (see [[architecture#AGENTS.md pipeline]])
- `skills/` — symlinked to `~/.pi/agent/skills/`
- `extensions/` — `.ts` extensions, symlinked
- `agents/`, `prompts/` — symlinked to `~/.pi/agent/`. Prompts has only `merge-worktree.md`; task/plan/tickets commands are handled by the `task-pipeline` extension
- `models.json`, `settings.json`, `mcp.json` — pi configuration files
- `pi-package/` — npm package source

### Adding skills or extensions

Create, stage, reapply. Auto-discovery handles the rest.

1. Create `skills/name/SKILL.md` or `extensions/name.ts`
2. `git add` the file
3. `devenv tasks run home:apply`

## Config index

All 44 configs under `home/configs/`:

| Config          | What it manages                                 |
| --------------- | ----------------------------------------------- |
| aliases         | shell aliases                                   |
| atuin           | shell history                                   |
| bash            | bash config                                     |
| bat             | cat replacement, catppuccin theme               |
| cargo           | Rust package manager                            |
| coreutils       | GNU coreutils                                   |
| delta           | git diff pager                                  |
| devenv          | devenv fish completions                         |
| eza             | ls replacement                                  |
| fd              | find replacement + `find-and-prune` script      |
| ffmpeg          | multimedia processing                           |
| fish            | default shell, config, plugins                  |
| fzf             | fuzzy finder                                    |
| ghostty         | terminal emulator (darwin-bin variant)          |
| git             | git, gh CLI, signing, worktree scripts          |
| gnugrep         | GNU grep                                        |
| google-chrome   | browser                                         |
| gpg             | GPG agent, SSH support, YubiKey signing         |
| iina            | media player                                    |
| jq              | JSON processor                                  |
| kanttiinit      | personal CLI tool                               |
| less            | pager config                                    |
| mas             | Mac App Store installs via activation script    |
| meetingbar      | calendar menu bar app                           |
| mermaid-cli     | diagram generation                              |
| neovim          | editor, LSPs, spell file, todo/daily scripts    |
| netnewswire     | RSS reader                                      |
| ollama          | LLM runner (prebuilt macOS binary)              |
| npm             | npm config                                      |
| orion           | browser                                         |
| password-store  | password manager with GPG                       |
| pi-coding-agent | pi CLI, extensions, skills, lat-md              |
| qpdf            | PDF tools + `combine-pdfs-in-folder` script     |
| ripgrep         | search tool                                     |
| sleep           | `disable-sleep` / `enable-sleep` scripts        |
| ssh             | SSH config (GPG agent provides keys)            |
| starship        | shell prompt                                    |
| symlinks        | out-of-store symlinks (pi sessions, Music dirs) |
| tree            | directory tree viewer                           |
| utils           | `listening`, `nukeport`, `trash-empty` scripts  |
| yazi            | file manager                                    |
| yt-dlp          | video downloader                                |
| yubikey-manager | `yk-status` script                              |
| zoxide          | directory jumper                                |
