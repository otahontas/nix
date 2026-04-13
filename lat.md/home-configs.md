# Home configs

One directory per tool under `home/configs/`, each with `default.nix`. Home-manager auto-imports them all.

## pi-coding-agent

Builds pi and lat-md from npm, wraps `pi` with PATH and API keys.

Extensions, skills, agents, prompts, and models symlink from the config directory to `~/.pi/agent/`.
