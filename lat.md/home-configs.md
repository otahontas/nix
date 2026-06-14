# Home configs

One directory per tool under `home/configs/` (49 configs), each with `default.nix`. Auto-imported by `lib.filesystem.listFilesRecursive` — add a directory, it appears.

Apply with `devenv tasks run home:apply`. Stage new files before applying; don't commit unless asked.

## Patterns

Conventions for writing home-manager configs.

- **Home manager first** — use `programs`/`services`, fallback to `pkgs`
- **Catppuccin** — global theme uses `catppuccin.enable = true` plus `autoEnable = true` to keep automatic port enrollment explicit
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

- **GPG/SSH** (`gpg/`) — YubiKey-based: gpg-agent with SSH support, GPG signing for git, `pinentry_mac` for GUI prompts, and SSH `IdentityAgent` through `programs.ssh.settings`
- **ghostty** — uses `ghostty-bin` (Linux-only `ghostty` lacks darwin support); symlinks config from XDG to Application Support where macOS Ghostty looks for it; enables title, attention, and border bell effects for Pi notifications
- **pi-coding-agent** — installs Pi from `github:lukasl-dev/pi.nix`, wraps it to load API key env vars and add local helper tools, and symlinks extensions/skills/prompts/models to `~/.pi/agent/`
- **password-store** — pass with GPG integration
- **input-source** — disables Control+Space input source switch shortcut for terminal/nvim pass-through
- **neovim** — blink.cmp with Copilot LSP + blink-copilot source; LSPs for Nix, shell, Lua; Ruby/Python providers disabled; custom spell file; ghost text disabled
- **git** — GPG-signed commits, allowed_signers, gh CLI helpers, worktree scripts
- **yazi** — file manager with git status, starship prompt, relative motions, and character jump; git fetchers share `group = "git"` for Yazi 26.5.6+

### pi-coding-agent structure

Directory layout of `home/configs/pi-coding-agent/`.

- `default.nix` — main config, installs `pi.nix`'s Pi package through the Home Manager module, wraps it to load pass-backed web/MCP API key env vars before startup, adds the Plannotator CLI, `rtk`, and Poppler to Pi's PATH, blocks `pass`, wraps `gpg` so only Git signing and signature verification can reach real GPG, then auto-discovers and symlinks local extensions, skills, and prompts
- `sources/GLOBAL_AGENTS.md` — source for global `~/.pi/agent/AGENTS.md` (see [[architecture#AGENTS.md pipeline]])
- `skills/` — local skills symlinked to `~/.pi/agent/skills/`; package-managed skills and extensions stay in `settings.json`
  - `ui/` — ui.sh Agent Skills stub matching the generic skill installed by `@uidotsh/install`; it points agents at the `uidotsh://ui` MCP resource
- `extensions/` — `.ts` extensions, auto-discovered and symlinked to `~/.pi/agent/extensions/`:
  - `rtk.ts` — intercepts bash tool calls, rewrites commands through `rtk` for token savings
  - `stop-hook.ts` — current Pi model decides whether to nudge agent after each response, using the active thinking level and emitting in-flight events for `notify.ts`
  - `guardrails.ts` — blocks non-conventional commits, `rm`, `npx`, `pass`/`gpg` command invocations (including absolute paths), non-standard worktree paths, and `--no-verify` commits
  - `custom-footer.ts` — starship prompt, token stats, model info, and extension statuses in TUI footer
  - `search-sessions.ts` — BM25 search over past pi conversations
  - `non-interactive.ts` — detects headless mode, injects no-chatter prompt
  - `name-session.ts` — names UI sessions from the first real user prompt with the current Pi model
  - `clone-cmd.ts` — `/clone-cmd` clones the current branch to a new session and copies a launch command
  - `notify.ts` — sends session-aware OSC 777 notifications with deterministic bodies and sanitized output
- Pi package resources and wrapper-only helper commands:
  - `pi-mcp-adapter` — MCP server integration, OAuth flow, tool discovery
  - `pi-web-access` — web search, content extraction, YouTube + video understanding
  - `pi-subagents` — multi-agent orchestration (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate)
  - `pi-caveman` — owns caveman prompt injection, `/caveman` session toggle, config UI, and footer status
  - `@plannotator/pi-extension` — Plannotator commands and skills
  - Plannotator CLI — pinned GitHub release binary exposed only inside Pi's wrapper PATH so the `plannotator-setup-goal` skill can run `plannotator setup-goal ...`
  - `pi-agent-goal` — provides the `/goal` command, `/goal import <path> --start`, branch-aware goal state, and goal progress tools
  - `pi-rtk-optimizer` — RTK command rewriting and tool output compaction
  - Unpinned NPM packages are updated with `pi update --extensions`
- Bundled agents come from the pi-subagents package (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate); no local `agents/` directory is needed
- `prompts/` — `merge-worktree.md`; symlinked to `~/.pi/agent/prompts/`
- `scripts/` — `build-session-index.sh` (launchd timer), `work-tickets.sh`, `merge-settings.sh` (activation hook)
- `models.json`, `settings.json`, `mcp.json` — pi configuration files; `settings.json` defaults to OpenAI Codex `gpt-5.5` with `xhigh` thinking, enables `gpt-5.5` and `gpt-5.3-codex-spark`, pins bundled `scout` and `reviewer` to Spark, and declares unpinned NPM Pi packages
- `mcp.json` — chrome-devtools MCP passes `--executable-path=/Users/otahontas/.nix-profile/bin/google-chrome` and `--isolated` so Puppeteer uses Nix Chrome and independent temp profiles
- `scripts/merge-settings.sh` — merges repo settings during activation and deletes stale `subagents.agentOverrides` before applying repo-managed overrides
- `home/flake.nix` input `pi-nix` (`github:lukasl-dev/pi.nix`) supplies the Pi package and Home Manager module

### stop-hook extension

Stop-hook gates automatic self-review with the active Pi model, so it follows the configured default model and thinking level instead of pinning a separate gatekeeper.

- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#askGatekeeper]] uses `ctx.model` and sets active thinking as `reasoning` when thinking is not `off`.
- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#shouldSendNudge]] still skips obvious completions and stops nudging after repeated gatekeeper failures.
- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#STOP_CHECK_PROMPT]] keeps follow-ups within the requested scope, so investigation-only requests report findings instead of starting fixes.
- `agent_end` only queues the self-review prompt after tool-using turns, and shared start/end events let `notify.ts` wait for the gatekeeper.

### name-session extension

Name-session assigns display names without depending on native notifications.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/name-session.ts#generateTitle]] and [[home/configs/pi-coding-agent/extensions/name-session.ts#looksLikeRealTask]].

- In UI sessions, the first real user prompt can generate a 2-6 word session title with the current Pi model. Manual and restored names win, greetings and extension-generated prompts are skipped, and the result is guarded against session switches before `pi.setSessionName` runs.
- Extension-generated prompts are skipped so `stop-hook.ts` follow-ups do not rename the session.
- Title generation is best effort and never breaks the agent loop.

### clone-cmd extension

Clone-cmd creates a new Pi session from the current branch without switching the active pane.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/clone-cmd.ts#copyToClipboard]].

- `/clone-cmd` copies `cd <cwd> && pi --session <session-id>` for a cloned session at the current leaf.
- The extension opens the current session file through a separate `SessionManager`, so the active pane stays on the original session.

### notify extension

Pi notifications carry useful context without model calls.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/notify.ts#buildNotificationBody]], [[home/configs/pi-coding-agent/extensions/notify.ts#canWriteNativeNotification]], and [[home/configs/pi-coding-agent/extensions/notify.ts#notify]].

- `agent_end` notifications only run in interactive TTY sessions. They wait for stop-hook gatekeeper checks, then send only if Pi is idle and has no pending messages.
- `stop-hook.ts` emits shared start/end events around [[home/configs/pi-coding-agent/extensions/stop-hook.ts#shouldSendNudge]], so notification timers can cancel stale turn-complete alerts when a follow-up starts.
- Body text is deterministic: failed bash command first, then `needs input` when the final assistant message appears blocked, otherwise `done`.
- OSC 777 title/body fields collapse whitespace, remove control characters, replace semicolons, and truncate output before writing to stdout. The notifier also emits BEL so Ghostty can trigger its configured title, attention, and border bell effects.

### pi-caveman package

Caveman response style comes from the package-managed `pi-caveman` extension instead of a local skill and AGENTS.md rule.

- Pi loads `npm:pi-caveman` from `settings.json`; the package stays unpinned so `pi update --extensions` can update it.
- The package provides `/caveman` for session-level toggles and `/caveman config` for the default level and footer status setting.
- The extension defaults new sessions to `full` caveman mode when `~/.pi/agent/caveman.json` is absent or sets `defaultLevel` to `full`.

### Adding skills or extensions

**Simple extensions** (single `.ts` files, no npm deps):

1. Create `extensions/name.ts`
2. `git add` the file
3. `devenv tasks run home:apply`

**Complex extensions** (with npm dependencies):

- Prefer a Pi package in `settings.json`; Pi installs missing packages on startup and `pi update --extensions` updates unpinned specs
- For first-party reusable extensions, publish an npm Pi package or use a direct git/local package source in `settings.json`

## Config index

All 49 configs under `home/configs/`:

| Config               | What it manages                                  |
| -------------------- | ------------------------------------------------ |
| aliases              | shell aliases                                    |
| atuin                | shell history                                    |
| bash                 | bash config                                      |
| bat                  | cat replacement, catppuccin theme                |
| cargo                | Rust package manager                             |
| coreutils            | GNU coreutils                                    |
| csvlens              | CSV terminal viewer                              |
| delta                | git diff pager                                   |
| devenv               | devenv fish completions                          |
| eza                  | ls replacement                                   |
| fd                   | find replacement + `find-and-prune` script       |
| ffmpeg               | multimedia processing                            |
| fish                 | default shell, config, plugins                   |
| fzf                  | fuzzy finder                                     |
| ghostty              | terminal emulator (darwin-bin variant)           |
| git                  | git, gh CLI, signing, worktree scripts           |
| glow                 | terminal markdown reader                         |
| gnugrep              | GNU grep                                         |
| google-chrome        | browser                                          |
| google-workspace-cli | Google Workspace CLI (`gws`) from upstream flake |
| gpg                  | GPG agent, SSH support, YubiKey signing          |
| iina                 | media player                                     |
| input-source         | disables Control+Space input source shortcut     |
| jq                   | JSON processor                                   |
| kanttiinit           | personal CLI tool                                |
| lazygit              | terminal UI for git                              |
| less                 | pager config                                     |
| mas                  | Mac App Store installs via activation script     |
| meetingbar           | calendar menu bar app                            |
| mermaid-cli          | diagram generation                               |
| mise                 | tool version manager with Bash/Fish hooks        |
| neovim               | editor, LSPs, spell file, todo/daily scripts     |
| netnewswire          | RSS reader                                       |
| ollama               | LLM runner (prebuilt macOS binary)               |
| orion                | browser                                          |
| password-store       | password manager with GPG                        |
| pi-coding-agent      | pi CLI, extensions, skills, lat-md               |
| qpdf                 | PDF tools + `combine-pdfs-in-folder` script      |
| ripgrep              | search tool                                      |
| sleep                | `disable-sleep` / `enable-sleep` scripts         |
| ssh                  | SSH config (GPG agent provides keys)             |
| starship             | shell prompt                                     |
| symlinks             | out-of-store symlinks (pi sessions, Music dirs)  |
| tree                 | directory tree viewer                            |
| utils                | `listening`, `nukeport`, `trash-empty` scripts   |
| yazi                 | file manager                                     |
| yt-dlp               | video downloader                                 |
| yubikey-manager      | `yk-status` script                               |
| zoxide               | directory jumper                                 |
