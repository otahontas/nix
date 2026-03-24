## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `web_search` and `fetch_content` tools for web searches
- Always use `devenv` cli and `devenv` skill to install tools, clis and commands.
  - When `devenv.nix` doesn't exist and a command/tool is missing, create an ad-hoc environment
  - When the setup is becomes complex create `devenv.nix` and run commands within
  - Use `devenv` skill

## Writing

- Use sentence case: "Next steps" not "Next Steps", "Plan overview" not "Plan Overview"
- For answering directly, sacrifice grammar over being concise unless specifically asked to write clearly
- When actually editing or creating text to be read by humans use skill `writing-clearly-and-concisely`.
- Prefer bullet points over paragraphs
- Never include time estimations (e.g., "day 1: do X, day 2: do Y", "this takes 1 week") unless the user specifically asks for them

## Git

- For non-interactive rebases, always run `GIT_EDITOR=true git rebase --continue`

## Git worktrees

- Do branch work in git worktrees under `<repo>/.worktrees/<branch>`, not in the main checkout
- Pi runs non-interactive bash tool calls, so do not rely on Fish aliases/functions like `gwnew`, `gwpr`, `gwcd`, `gwprune`, `git-worktree-*`
- Use explicit bash-safe commands:
  - New branch worktree:
    - `repo_root=$(git rev-parse --show-toplevel)`
    - `mkdir -p "$repo_root/.worktrees"`
    - `git worktree add "$repo_root/.worktrees/$branch" -b "$branch"`
  - PR branch worktree (branch name known):
    - `repo_root=$(git rev-parse --show-toplevel)`
    - `mkdir -p "$repo_root/.worktrees"`
    - `pr_number=$(gh pr list --state open --head "$branch" --json number --jq '.[0].number')`
    - `git fetch origin "pull/$pr_number/head:$branch"`
    - `git worktree add "$repo_root/.worktrees/$branch" "$branch"`
  - Remove/prune:
    - `git worktree remove "$repo_root/.worktrees/$branch" --force`
    - `git branch -D "$branch"` (only if branch exists)
  - Run commands in a worktree (each bash call starts from session cwd):
    - `cd "$repo_root/.worktrees/$branch" && <command>`

## Coding specific guidelines:

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Only fix what's asked - no bonus improvements, refactoring, or extra comments unless requested

## Multi-step task workflow:

- For complex tasks: write plan in markdown file first. Use your judgment to determine if a task is "complex": if it involves multiple steps, file modifications, or research, it's better to plan first.
- Always clarify users intention unless request is completely clear
- If uncertain, say so immediately - don't guess what to implement
- Work incrementally:
  1. complete step
  2. explicitly run verification commands (e.g., build, lint, test).
  3. if verification passes, commit and mark step as done. If not, fix and verify. Only commit when a step is fully working.
- Don't create plans/markdown for simple single-step tasks

## Local development scripts:

- Use `.local_scripts/` for temporary verification scripts that shouldn't be committed
- Scripts can be messy and repo-specific
