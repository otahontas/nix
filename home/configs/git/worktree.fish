function __git_worktree_names
    # Use git-common-dir to get the main repo's .git dir, works from any worktree
    set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null | string trim)
    if test -z "$git_common_dir"
        return
    end

    # The main repo root is the parent of .git
    set -l repo_root (dirname "$git_common_dir")
    set -l worktrees_dir "$repo_root/.worktrees"

    if not test -d "$worktrees_dir"
        return
    end

    for dir in $worktrees_dir/*/
        basename "$dir"
    end
end

function __git_pr_numbers
    set -l prs (gh pr list --json number,title,author,createdAt --limit 50 2>/dev/null)
    if test -z "$prs"
        return
    end

    echo $prs | jq -r '.[] | "\(.number)\t\(.author.login) \(.createdAt | split("T")[0]) \(.title)"'
end

function git-worktree-new --description "Create a new git worktree with a new branch"
    if test (count $argv) -lt 1
        echo "Usage: git-worktree-new <branch_name>"
        return 1
    end

    set -l branch_name $argv[1]
    set -gx HUSKY 0

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null | string trim)
    if test -z "$repo_root"
        echo "Error: Not in a git repository"
        return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"
    mkdir -p "$repo_root/.worktrees"

    echo "Creating worktree for branch: $branch_name"
    echo "Location: $worktree_path"

    set -l has_git_crypt (test -d "$repo_root/.git/git-crypt" && echo "true" || echo "false")

    if test "$has_git_crypt" = true
        echo "Detected git-crypt encryption"
        git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" -b "$branch_name"

        set -l worktree_basename (basename "$worktree_path")
        set -l git_crypt_target "$repo_root/.git/git-crypt"
        set -l git_crypt_link "$repo_root/.git/worktrees/$worktree_basename/git-crypt"

        if test -d "$git_crypt_target" -a ! -e "$git_crypt_link"
            ln -s "$git_crypt_target" "$git_crypt_link"
        end

        cd "$worktree_path"
        git checkout -- . 2>/dev/null
    else
        git worktree add "$worktree_path" -b "$branch_name"
        cd "$worktree_path"
    end

    set -l status_output (git status --short | string trim)
    if test -n "$status_output"
        echo "Warning: Worktree has uncommitted changes:"
        echo "$status_output"
    end

    echo ""
    echo "✓ Worktree created successfully"
end

function git-worktree-pr --description "Create a worktree from a GitHub PR"
    if test (count $argv) -lt 1
        echo "Usage: git-worktree-pr <pr_number>"
        return 1
    end

    set -l pr_number $argv[1]
    set -gx HUSKY 0

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null | string trim)
    if test -z "$repo_root"
        echo "Error: Not in a git repository"
        return 1
    end

    set -l pr_branch (gh pr view $pr_number --json headRefName -q .headRefName 2>/dev/null | string trim)
    if test -z "$pr_branch"
        echo "Error: Failed to get PR #$pr_number info"
        return 1
    end

    set -l worktree_dir_name "pr-$pr_number-$pr_branch"
    set -l worktree_path "$repo_root/.worktrees/$worktree_dir_name"
    mkdir -p "$repo_root/.worktrees"

    echo "Fetching PR #$pr_number..."
    git fetch origin "pull/$pr_number/head:$pr_branch" 2>&1 | string match -v "From *"

    echo "Creating worktree for PR #$pr_number..."

    set -l has_git_crypt (test -d "$repo_root/.git/git-crypt" && echo "true" || echo "false")

    if test "$has_git_crypt" = true
        echo "Detected git-crypt encryption"
        git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" "$pr_branch"

        set -l worktree_basename (basename "$worktree_path")
        set -l git_crypt_target "$repo_root/.git/git-crypt"
        set -l git_crypt_link "$repo_root/.git/worktrees/$worktree_basename/git-crypt"

        if test -d "$git_crypt_target" -a ! -e "$git_crypt_link"
            ln -s "$git_crypt_target" "$git_crypt_link"
        end

        cd "$worktree_path"
        git checkout -- . 2>/dev/null
    else
        git worktree add "$worktree_path" "$pr_branch"
        cd "$worktree_path"
    end

    set -l status_output (git status --short | string trim)
    if test -n "$status_output"
        echo "Warning: Worktree has uncommitted changes:"
        echo "$status_output"
    end

    echo ""
    echo "✓ PR #$pr_number checked out successfully"
    echo "Location: $worktree_path"
end

function git-worktree-prune --description "Remove a git worktree and its branch"
    if test (count $argv) -lt 1
        echo "Usage: git-worktree-prune <branch_name>"
        return 1
    end

    set -l branch_name $argv[1]
    set -gx HUSKY 0

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null | string trim)
    if test -z "$repo_root"
        echo "Error: Not in a git repository"
        return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"

    if not test -d "$worktree_path"
        echo "Error: Could not find worktree for branch '$branch_name'"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
    end

    echo "Removing worktree: $worktree_path"
    git worktree remove "$worktree_path" --force
    echo "✓ Worktree removed"

    if git show-ref --verify --quiet "refs/heads/$branch_name"
        echo "Deleting branch: $branch_name"
        git branch -D "$branch_name"
        echo "✓ Branch deleted"
    end
end

function git-worktree-cd --description "Change directory to a git worktree"
    if test (count $argv) -lt 1
        echo "Usage: git-worktree-cd <branch_name>"
        return 1
    end

    set -l branch_name $argv[1]

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null | string trim)
    if test -z "$repo_root"
        echo "Error: Not in a git repository"
        return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"

    if not test -d "$worktree_path"
        echo "Error: Could not find worktree for branch '$branch_name'"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
    end

    cd "$worktree_path"
end

# Completions for worktree commands
complete -c git-worktree-prune -f -a "(__git_worktree_names)"
complete -c git-worktree-cd -f -a "(__git_worktree_names)"
complete -c git-worktree-pr -f -a "(__git_pr_numbers)"
