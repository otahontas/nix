---
name: git-worktree
description: Standard git worktree workflow for this environment. Use when creating, opening, reviewing, or pruning branch worktrees.
---

# Git worktree workflow

Use this skill when the task needs branch-isolated checkouts.

## Rules

- Keep worktrees under `<repo>/.worktrees/<branch>`
- Use branch name as the shared identifier for create, open, and prune
- Do not rely on Fish aliases/functions (`gwnew`, `gwpr`, `gwcd`, `gwprune`, `git-worktree-*`) because pi tool calls run non-interactive bash
- Keep the main checkout clean, do branch work in its worktree

## Create a new branch worktree

```bash
branch="<branch>"
repo_root=$(git rev-parse --show-toplevel)
mkdir -p "$repo_root/.worktrees"
git worktree add "$repo_root/.worktrees/$branch" -b "$branch"
```

## Create a worktree from an open GitHub PR branch

```bash
branch="<branch>"
repo_root=$(git rev-parse --show-toplevel)
mkdir -p "$repo_root/.worktrees"
pr_number=$(gh pr list --state open --head "$branch" --json number --jq '.[0].number')
if [ -z "$pr_number" ] || [ "$pr_number" = "null" ]; then
  echo "No open PR found for branch '$branch'" >&2
  exit 1
fi
git fetch origin "pull/$pr_number/head:$branch"
git worktree add "$repo_root/.worktrees/$branch" "$branch"
```

## Run commands in a worktree

Each pi bash call starts from the session working directory. Use explicit `cd`:

```bash
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root/.worktrees/$branch" && <command>
```

## Open and inspect

```bash
git worktree list
```

## Prune a worktree and branch

```bash
branch="<branch>"
repo_root=$(git rev-parse --show-toplevel)
git worktree remove "$repo_root/.worktrees/$branch" --force
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git branch -D "$branch"
fi
```
