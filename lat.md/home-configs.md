# Home configs

One directory per tool under `home/configs/`, each with `default.nix`. Home-manager auto-imports them all.

## Conventions

Rules that apply across all tool configs.

- **Programs first** — prefer `programs.<tool>` options over raw `home.packages`.
- **Fish integration** — aliases via `shellAliases`, interactive init via `builtins.readFile` from external `.fish` files, completions in `fish/conf.d/`.
- **GUI apps** — home-manager packages with `targets.darwin.copyApps.enable = true` for Spotlight visibility. Mac App Store apps go in `masApps`.
- **LaunchAgents** — `launchd.agents` for auto-start daemons.
- **Session variables** — `sessionVariables` for paths and env config.

## pi-coding-agent

Builds pi and lat-md from npm, wraps `pi` with PATH and API keys.

Extensions, skills, agents, prompts, and models symlink from the config directory to `~/.pi/agent/`.
