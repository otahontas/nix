# Home configs

One directory per tool under `home/configs/` (52 configs), each with `default.nix`. The home flake imports only `home/configs/*/default.nix`; helper `.nix` files must be called explicitly.

Apply with `devenv tasks run home:apply`. Stage new files before applying; don't commit unless asked.

## Patterns

Conventions for writing home-manager configs.

- **Home manager first** — use `programs`/`services`, fallback to `pkgs`
- **Catppuccin** — global theme uses `catppuccin.enable = true` plus `autoEnable = true` to keep automatic port enrollment explicit
- **Session variables** for paths and environment config
- **GUI apps** — prefer home-manager when nixpkgs has darwin `.app` bundle; `targets.darwin.copyApps.enable = true` for Spotlight
- **Manual apps** — keep system-wide vendor installers in [[system-config#Manual applications]] instead of forcing them into Home Manager
- **LaunchAgents** via `launchd.agents` for auto-start
- **Out-of-store symlinks** via `config.lib.file.mkOutOfStoreSymlink` (see `symlinks/`)
- **Mac App Store** apps via a `mas` activation script that calls the store path directly; `mas` stays out of the user PATH (pending native nix-darwin module)

## Fish integration

Each tool owns its fish integration in its own config directory:

- Aliases → `shellAliases`
- Interactive init → `builtins.readFile` from an external file in the owning config directory, never inline
- Devenv fish auto-activation lives in `devenv/`, not `fish/`
- Completions → `xdg.configFile."fish/conf.d/<tool>.fish".text` (avoids overriding upstream)
- Functions → always with `description` and `body` from external file

## Shell scripts

Scripts live in `scripts/` subdirectories next to `default.nix`, loaded via `builtins.readFile` + `writeShellScriptBin`. Related scripts use `basename "$0"` dispatch; filename-sensitive scripts use arrays/null delimiters.

Configs with scripts: `fd`, `git`, `neovim`, `pi-coding-agent`, `qpdf`, `sleep`, `utils`, `yubikey-manager`.

## Notable configs

Configs worth documenting beyond a table row.

- **GPG/SSH** (`gpg/`) — YubiKey-based: gpg-agent with SSH support, GPG signing for git, `pinentry_mac` for GUI prompts, and SSH `IdentityAgent` through `programs.ssh.settings`
- **ghostty** — uses `ghostty-bin` (Linux-only `ghostty` lacks darwin support); symlinks config from XDG to Application Support where macOS Ghostty looks for it; enables title, attention, and border bell effects for Pi notifications
- **pi-coding-agent** — installs Pi from `github:lukasl-dev/pi.nix`; see [[pi-coding-agent]] for wrapper, package, extension, skill, and prompt details
- **iina** — installs the app and uses `duti` only from the activation store path for media file associations
- **discord** — installs the signed brew-nix cask and keeps Discord's mutable settings compatible with GUI launch updates
- **password-store** — pass with GPG integration plus `pass-otp`, `pass-genphrase`, and `pass-update`
- **neovim** — blink.cmp without copilot source; `copilot.lua` plugin for inline Copilot suggestions, with panel disabled and telemetry set to off; root `.nvim.lua` adds the repo runtime, `.nvim/lua/local_lsp.lua` enables repo LSPs, and `.nvim/lsp/` holds custom configs; Ruby/Python providers disabled; ghost text disabled
- **git** — GPG-signed commits, allowed_signers, gh CLI helpers, global ignores, worktree scripts
- **yazi** — file manager with git status, starship prompt, relative motions, and character jump; git fetchers share `group = "git"` for Yazi 26.5.6+

### git worktree helpers

Worktree helpers assume branch, worktree, and path names are dash-only.

Bash and Fish helpers keep branch names and `.worktrees/<branch>` paths identical. Slash-containing branch names are out of policy and blocked by Pi guardrails instead of normalized.

### neovim

Neovim is Home Manager-managed, while root `.nvim.lua` adds `.nvim/` for repo-local Lua modules and LSP overrides.

- Markdown diagram/image rendering loads on Markdown buffers, skips headless sessions, and reports setup failures with notifications instead of breaking startup.
- nvim-lint is installed with a global save autocmd; repo-local `.nvim/lua/local_lint.lua` defines file-path Markdown linting and chooses which linters apply.
- SchemaStore.nvim is installed so repo-local `.nvim/lsp/` configs can feed SchemaStore catalogs and repo-specific schema extras into JSON/YAML language servers.
- LSP reference highlights run on `CursorHold` and clear on cursor movement or buffer leave, avoiding a document-highlight request on every cursor move.
- The Neovim wrapper PATH includes `tree-sitter` for Treesitter health and a private `grealpath` wrapper for yazi relative-path copy without exposing `grealpath` globally.
- GitHub permalink copy resolves the repository from the current buffer path before running `git` or `gh` commands. Copilot now uses `copilot.lua` with inline suggestions, auto-trigger enabled, panel disabled, and telemetry off.

## Config index

All 52 configs under `home/configs/`:

| Config               | What it manages                                   |
| -------------------- | ------------------------------------------------- |
| aliases              | shell aliases                                     |
| appcleaner           | GUI app uninstaller                               |
| atuin                | shell history                                     |
| bash                 | bash config with sourced worktree functions       |
| bat                  | cat replacement, catppuccin theme                 |
| cargo                | Rust package manager                              |
| coreutils            | GNU coreutils                                     |
| csvlens              | CSV terminal viewer                               |
| delta                | git diff pager                                    |
| devenv               | devenv package, fish auto-activation, completions |
| discord              | chat app                                          |
| eza                  | ls replacement                                    |
| fd                   | find replacement + `find-and-prune` script        |
| ffmpeg               | multimedia processing                             |
| fish                 | default shell, config, plugins                    |
| fzf                  | fuzzy finder                                      |
| ghostty              | terminal emulator (darwin-bin variant)            |
| git                  | git, gh CLI, signing, global ignores, scripts     |
| glow                 | terminal markdown reader                          |
| gnugrep              | GNU grep                                          |
| google-chrome        | browser                                           |
| google-cloud-sdk     | gcloud CLI (`pkgs.google-cloud-sdk`)              |
| google-workspace-cli | Google Workspace CLI (`gws`) from upstream flake  |
| gpg                  | GPG agent, SSH support, YubiKey signing           |
| iina                 | media player                                      |
| jq                   | JSON processor                                    |
| kanttiinit           | personal CLI tool                                 |
| lazygit              | terminal UI for git                               |
| less                 | pager config                                      |
| libreoffice          | office suite                                      |
| mas                  | Mac App Store installs via activation script      |
| meetingbar           | calendar menu bar app                             |
| mermaid-cli          | diagram generation                                |
| mise                 | tool version manager with Bash/Fish hooks         |
| neovim               | editor, LSPs, todo/daily scripts                  |
| netnewswire          | RSS reader                                        |
| ollama               | LLM runner (prebuilt macOS binary)                |
| orion                | browser                                           |
| password-store       | password manager with GPG                         |
| pi-coding-agent      | pi CLI, extensions, skills, lat-md                |
| qpdf                 | PDF tools + safe `combine-pdfs-in-folder` script  |
| ripgrep              | search tool                                       |
| sleep                | `disable-sleep` / `enable-sleep` scripts          |
| ssh                  | SSH config (GPG agent provides keys)              |
| starship             | shell prompt                                      |
| symlinks             | out-of-store symlinks (pi sessions, Music dirs)   |
| tree                 | directory tree viewer                             |
| utils                | `listening`, `nukeport`, `trash-empty` scripts    |
| yazi                 | file manager                                      |
| yt-dlp               | video downloader                                  |
| yubikey-manager      | `yk-status` script                                |
| zoxide               | directory jumper                                  |
