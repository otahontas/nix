---
name: devenv
description: Use when working in a repo that uses devenv (devenv.nix/devenv.yaml/.envrc) or when the user mentions devenv, direnv+devenv, languages.*, services.*, processes, tasks, git-hooks, profiles, outputs, containers, devenv shell/up/test/search/update.
---

# Devenv

Devenv is a Nix-based dev environment runner. Prefer it over ad-hoc installs and global tooling.

## Default behavior (always)

- If the repo has `devenv.nix` / `devenv.yaml`:
  - Prefer running commands via devenv:
    - `devenv shell -- <cmd>` (one-off commands)
    - `devenv tasks run <task>` (project-defined workflows)
    - `devenv test` (default “CI check” when available)
  - Prefer starting background deps via devenv:
    - `devenv up` (processes + services)
- Don’t invent new setup steps if devenv already defines them.
- Don’t bypass devenv with global installs unless the user asks.

## What to look for in a repo

- `devenv.nix`: main configuration (Nix module system)
- `devenv.yaml`: inputs + imports (composition)
- `devenv.lock`: pinned inputs
- `.envrc`: usually `use devenv` (direnv auto-activation)

## Core commands (starting point)

- Setup / enter
  - `devenv init`
  - `devenv shell` (or `direnv allow` if `.envrc` uses devenv)
- Run things
  - `devenv up` (runs configured processes; services often add their own processes)
  - `devenv tasks list` / `devenv tasks run <name>`
- Inspect / debug
  - `devenv info`
  - `devenv repl`
  - `devenv search <query>` (find packages + options)
- Update
  - `devenv update` (refresh lockfile)
  - `devenv changelogs` (see breaking/behavior changes)

## What devenv can do (feature map)

- Tools in PATH
  - `packages = [ pkgs.git pkgs.jq ... ];`
- Language runtimes and ecosystem helpers
  - `languages.*` (enable language, set versions, enable package managers)
- Local services (db/queues/etc)
  - `services.*` (postgres, redis, mysql, …)
- Long-running dev processes
  - `processes.*` + `devenv up` (process-compose; logs under `$DEVENV_STATE`)
- Task runner (recommended for workflows)
  - `tasks.*` + `devenv tasks run ...` (dependencies, caching via `status`, file watching via `execIfModified`)
- Git hooks
  - `git-hooks.hooks.*` (pre-commit integration)
- Profiles
  - `profiles.*` + `devenv --profile <name> shell|up` (activate subsets/variants)
- Outputs (build artifacts)
  - `outputs.*` + `devenv build [outputs.<name>]`
- Containers (OCI)
  - `devenv container build|run|copy <name>`
- Secrets
  - dotenv integration, and SecretSpec integration (recommended pattern: `devenv shell -- secretspec run -- <cmd>`)

## Minimal troubleshooting

- Re-evaluate environment: `devenv info` (or `devenv shell -v`)
- Process issues: check `$DEVENV_STATE/process-compose/` logs
- Option/package name uncertainty: `devenv search <term>`
