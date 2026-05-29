# Home configs

One directory per tool under `home/configs/` (45 configs), each with `default.nix`. Auto-imported by `lib.filesystem.listFilesRecursive` — add a directory, it appears.

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
- **pi-coding-agent** — wraps `pkgs.pi-coding-agent` with PATH, API keys, and Node module aliases for extensions; extensions/skills/agents/prompts/models symlink to `~/.pi/agent/`
- **password-store** — pass with GPG integration
- **input-source** — disables Control+Space input source switch shortcut for terminal/nvim pass-through
- **neovim** — blink.cmp with Copilot LSP + blink-copilot source; LSPs for Nix, shell, Lua; custom spell file; ghost text disabled
- **git** — GPG-signed commits, allowed_signers, gh CLI helpers, worktree scripts

### pi-coding-agent structure

Directory layout of `home/configs/pi-coding-agent/`.

- `default.nix` — main config, wraps `pkgs.pi-coding-agent` to load pass secrets, PATH tools, and Node module aliases for extensions, then auto-discovers and symlinks everything below; accepts `pi-subagents`, `pi-ralph-loop`, `pi-mcp-adapter`, `pi-web-access` as parameters
- `sources/GLOBAL_AGENTS.md` — source for global `~/.pi/agent/AGENTS.md` (see [[architecture#AGENTS.md pipeline]])
- `skills/` — symlinked to `~/.pi/agent/skills/`
- `extensions/` — `.ts` extensions, auto-discovered and symlinked to `~/.pi/agent/extensions/`:
  - `model-quota.ts` — status bar quota display for GitHub Copilot, OpenAI Codex, and OpenCode Go (see model-quota extension below)
  - `rtk.ts` — intercepts bash tool calls, rewrites commands through `rtk` for token savings
  - `stop-hook.ts` — gatekeeper model decides whether to nudge agent after each response; tries local Ollama then cloud fallback
  - `guardrails.ts` — blocks non-conventional commits, `rm`, `npx`, `pass`/`gpg`, non-standard worktree paths, `--no-verify` commits
  - `custom-footer.ts` — starship prompt + token stats + model info in TUI footer
  - `search-sessions.ts` — BM25 search over past pi conversations
  - `non-interactive.ts` — detects headless mode, injects no-chatter prompt
  - `notify.ts` — sends OSC 777 notification on agent completion
- Nix-built extensions (symlinked from `home/packages/`):
  - `pi-mcp-adapter/` — MCP server integration, OAuth flow, tool discovery
  - `pi-web-access/` — web search, content extraction, YouTube + video understanding
  - `pi-subagents/` — multi-agent orchestration (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate)
  - `pi-ralph-loop/` — autonomous coding loops with `/ralph` command and RALPH.md goal files
- `agents/` — empty; bundled agents come from pi-subagents package (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate)
- `prompts/` — `merge-worktree.md`; symlinked to `~/.pi/agent/prompts/`
- `scripts/` — `build-session-index.sh` (launchd timer), `work-tickets.sh`, `merge-settings.sh` (activation hook)
- `models.json`, `settings.json`, `mcp.json` — pi configuration files
- `home/packages/pi-mcp-adapter.nix` — `buildNpmPackage` fetching pi-mcp-adapter v2.6.0 from GitHub; vendored lockfile copied in `postPatch` (upstream omits it)
- `home/packages/pi-web-access.nix` — `buildNpmPackage` fetching pi-web-access v0.10.7 from GitHub
- `home/packages/pi-subagents.nix` — `buildNpmPackage` fetching pi-subagents v0.24.2 from GitHub; vendored lockfile copied in `postPatch` (upstream omits it)
- `home/packages/pi-ralph-loop.nix` — `buildNpmPackage` fetching pi-ralph-loop v1.8.0 from GitHub; ships skills (ralph-loop, ralph-draft, ralph-finalize) to `~/.pi/agent/skills/`

### model-quota extension

Status bar quota display for GitHub Copilot, OpenAI Codex, and OpenCode Go. Returns `QuotaInfo` (never null) — errors display inline:

- GitHub Copilot: `unavailable`, `no premium data`, `cannot parse usage`
- OpenAI Codex: `unavailable (check /login)` — needs OAuth login via `/login`; fetches from `https://chatgpt.com/backend-api/wham/usage` using the access token from `auth.json["openai-codex"]`
- OpenCode Go: `quota API pending` (API endpoint 404, no scraper creds), `check auth` (scraper configured but failed), `no auth` (no API key or scraper creds)

Manual `/model-quota` command shows all three providers. Auto-refreshes every 5 minutes.

**OpenCode Go quota fetching:**

- First tries API endpoint `/zen/go/v1/usage` (PR #16513, unmerged) with the API key from `auth.json`
- Falls back to scraping `https://opencode.ai/workspace/{id}/go` with env vars `OPENCODE_GO_WORKSPACE_ID` and `OPENCODE_GO_AUTH_COOKIE` (auth cookie from browser)

**To enable the scraper:**

1. Log into opencode.ai in your browser and navigate to your Go dashboard
2. Get workspace ID from the URL: `https://opencode.ai/workspace/{ID}/go`
3. Get auth cookie from browser dev tools (F12 → Application → Storage → Cookies → copy `auth` value, starts with `Fe26.2**`)
4. Store in pass:
   - `pass insert api/opencode-go-workspace-id` — paste your workspace ID
   - `pass insert api/opencode-go-auth-cookie` — paste your auth cookie
5. Rebuild home-manager (`devenv tasks run home:apply`) to pick up the new pass entries in the pi wrapper script

Once set, restart pi. Status bar shows `5h: 12% (4h) | wk: 35% (2d) | mo: 8% (29d)`. If cookie expires, refresh it from browser and update pass.

### Adding skills or extensions

**Simple extensions** (single `.ts` files, no npm deps):

1. Create `extensions/name.ts`
2. `git add` the file
3. `devenv tasks run home:apply`

**Complex extensions** (with npm dependencies):

- Add to `home/packages/` as a `buildNpmPackage` derivation — see existing `.nix` files for the pattern (`dontNpmBuild = true`, `cp -r . $out/`)
- If upstream omits `package-lock.json`, generate one (`npm install --package-lock-only`) and vendored it; reference it via `postPatch` like pi-mcp-adapter and pi-subagents do
- Pass through `extraSpecialArgs` in `home/flake.nix`
- Symlink in `default.nix`

## Config index

All 45 configs under `home/configs/`:

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
| input-source    | disables Control+Space input source shortcut    |
| jq              | JSON processor                                  |
| kanttiinit      | personal CLI tool                               |
| less            | pager config                                    |
| mas             | Mac App Store installs via activation script    |
| meetingbar      | calendar menu bar app                           |
| mermaid-cli     | diagram generation                              |
| mise            | tool version manager with Bash/Fish hooks       |
| neovim          | editor, LSPs, spell file, todo/daily scripts    |
| netnewswire     | RSS reader                                      |
| ollama          | LLM runner (prebuilt macOS binary)              |
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
