# AGENTS.md

## Tool

- Always use `trash` instead of `rm` for file deletion
- Always use `devenv` for developer environments
  - When `devenv.nix` exists: `devenv shell -- <cmd>`, `devenv up`, `devenv tasks run <task>`
  - When `devenv.nix` doesn't exist and a tool is missing: `devenv --option languages.<lang>.enable:bool true shell`
  - When setup gets complex, create `devenv.nix`
  - Don't bypass devenv with global installs
  - `devenv search <query>` to find packages and options
- When working with external libraries, use MCP tools (`context7`, `githits` and tools for specific libraries, such as `astro`, `cloudflare` if available ) to look up docs and examples instead of guessing APIs

## Git

- For non-interactive rebases, always run `GIT_EDITOR=true git rebase --continue`
- Worktree conventions in `git-worktrees` skill

## Coding specific guidelines

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Only fix what's asked - no bonus improvements, refactoring, or extra comments unless requested
- Don't reorganize imports or rename variables unless explicitly asked to
- Use existing patterns and conventions in the codebase — same error shapes, same file structure, same naming. Don't invent new approaches when there's already a working one.

## General workflow

- Always clarify users intention unless request is completely clear
- When debugging, run diagnostic commands and present findings before proposing a fix. Don't jump to solutions.
- When user says "investigate", "check", "inspect", or "audit", only investigate and report findings. Don't implement changes unless explicitly told to.

## Local development scripts

- Use `.local_scripts/` for temporary, messy, repo-specific scripts that shouldn't be committed
