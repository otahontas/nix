# TODO

## Shell + Terminal
- [ ] Port `.zshenv` and the full `.config/zsh` tree (paths, env exports, helper functions) to `programs.zsh` so the current `conf.d` modules such as `21_path.zsh`, `22_env-base.zsh`, `30_homebrew.zsh`, and the git/gh/llm helpers live in the flake instead of untracked files.
- [ ] Vendor the Antidote plugin stack defined in `.config/zsh/.zsh_plugins.txt` and stop relying on the Homebrew `antidote` formula; express the plugins as `programs.zsh.plugins` or managed derivations.
- [ ] Recreate the custom shell helpers (git-worktree functions, gh+fzf pickers, pnpm completion cache, safe-chain init, `update-packages` maintenance script) inside Home Manager (`home.file` + `programs.zsh.initExtra`) so that shell behavior is reproducible.
- [ ] Package the [`nu_plugin_skim`](https://github.com/idanarye/nu_plugin_skim) binary via Home Manager (e.g., `cargo install` + `programs.nushell.plugins`) so skim integrates directly with Nushell instead of relying on env variables alone.
- [ ] Remove the handwritten `brew()` wrapper once formulas/casks are declared in `nix-darwin.homebrew.*`, and source the Brewfile from the flake rather than `~/.local/share/brew/brewfile`.

## CLI Configs Outside the Flake
- [ ] Convert `~/.config/commitlint/commitlint.config.mjs` into an `xdg.configFile` or inline HM module.
- [ ] Template `~/.config/gptcommit/config.toml` and manage its OpenAI API key via a secrets solution (sops-nix/agenix) so the plaintext token leaves the working tree.
- [ ] Move the package-manager configs into Nix: `~/.config/npm/npmrc`, `~/.config/pnpm/rc`, and `~/.config/wget/wgetrc` along with the `Volta`/`GOPATH` env vars that reference them.
- [ ] Check in the smaller dotfiles that are currently ad-hoc: `~/.config/kanttiinit/config.toml`, `~/.config/op/config`, `~/.config/neonctl/credentials.json` (needs secrets), `~/.config/.jira/.config.yml`, `.config/.copilot/config.json`, `.config/github-copilot/*`, and the custom keyboard layout file living under `~/.config/U.S. International wo dead keys.keylayout.txt`.
- [ ] Package or vendor the external assets referenced from `.config/zsh/conf.d/46_safe-chain.zsh` so `~/.safe-chain` is reproducible.

## Secrets & Credentials
- [ ] Store the npm auth token (`~/.config/npm/npmrc`) and Neon/OpenAI credentials (`~/.config/neonctl/credentials.json`, `~/.config/gptcommit/config.toml`) in an encrypted secret backend and expose them to programs via environment variables instead of plain text files.
- [ ] Audit other auth material in `~/.aws`, `~/.gnupg`, `.password-store`, `.ssh`, `.op`, and `.ollama` and decide which parts should be generated (keys) vs. synced (configs) through Nix.

## Homebrew Formulas
- [ ] After migrating, uninstall formulas already supplied by Nix (`bat`, `coreutils`, `fzf`, `gh`, `git`, `git-delta`, `choose-gui`, `skhd`, `just`, `nixfmt`, `neovim`, `nushell`, `starship`, `yazi`, `zellij`, `zoxide`, etc.) to avoid duplicate toolchains.
- [ ] Add the remaining Brew CLI tools to `home.packages` or per-app modules: `antidote`, `asciinema`, `awscli`, `bash`, `commitlint`, `csvkit`, `deno`, `eza`, `fd`, `ffmpeg`, `gcc`, `git-crypt`, `gitleaks`, `gnupg`, `go`, `grep`, `imagemagick`, `jira-cli`, `jq`, `llm`, `lua`, `neonctl`, `ollama`, `pdfgrep`, `pinentry-mac/pinentry-touchid`, `pkgconf`, `ripgrep`, `rustup`/`rust`, `sevenzip`, `up`, `uv`, `viu`, `volta`, `wget`, `yt-dlp`, `bun`, and `gptcommit`. For items without upstream nixpkgs (e.g., `pinentry-touchid`, `gptcommit` tap), create overlays or fetch-from-GitHub derivations.
- [ ] Declare the Brew taps from `~/.local/share/brew/brewfile` (`jorgelbg/tap`, `m99coder/tap`, `oven-sh/bun`, `zurawiki/brews`) via `nix-darwin.homebrew.taps` so that tap setup is automated.

## Homebrew Casks
- [ ] Mirror the GUI installs called out in the Brewfile (`1password@beta`, `1password-cli@beta`, `android-platform-tools`, `docker-desktop`, `codex`, `font-victor-mono-nerd-font`, `google-chrome`, `iina`, `netnewswire`, `spotify`, etc.) using `nix-darwin.homebrew.casks` or, where possible, nixpkgs packages/applications.
- [ ] For music/video tooling (Arturia, Native Access, Softube, Waves, Focusrite, Izotope) that lack nixpkgs recipes, document the manual steps or wrap them via `homebrew.casks` to keep the setup declarative.

## Automation
- [ ] Express the current `justfile` tasks (format/build/check) as part of the flake outputs or keep `just` managed via Nix and ensure contributors invoke the same commands with `nix run`.
