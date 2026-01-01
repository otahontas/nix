# Git worktree integration with git-crypt support

# === Helper functions (private) ===
function _git_worktree_init() {
    export HUSKY=0
    # Note: `git root` is a custom alias defined in git config (alias.root = rev-parse --show-toplevel)
    git root 2>/dev/null || { echo "Error: Not in a git repository" >&2; return 1; }
}

function _git_worktree_has_git_crypt() {
    local repo_root="$1"
    [ -d "$repo_root/.git/git-crypt" ]
}

function _git_worktree_get_path() {
    local repo_root="$1"
    local branch_name="$2"

    mkdir -p "$repo_root/.worktrees"
    echo "$repo_root/.worktrees/$branch_name"
}

function _git_worktree_create_and_enter() {
    local repo_root="$1"
    local worktree_path="$2"
    local branch_name="$3"
    shift 3
    local git_worktree_args=("$@")

    if _git_worktree_has_git_crypt "$repo_root"; then
        echo "Detected git-crypt encryption"
        git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" "${git_worktree_args[@]}"

        local worktree_basename=$(basename "$worktree_path")
        local git_crypt_target="$repo_root/.git/git-crypt"
        local git_crypt_link="$repo_root/.git/worktrees/$worktree_basename/git-crypt"

        # Improved: Add error handling for symlink
        if [[ -d "$git_crypt_target" ]]; then
            if [[ ! -e "$git_crypt_link" ]]; then
                ln -s "$git_crypt_target" "$git_crypt_link"
            fi
        fi

        cd "$worktree_path"
        git co -- . 2>/dev/null || true
    else
        git worktree add "$worktree_path" "${git_worktree_args[@]}"
        cd "$worktree_path"
    fi
}

function _git_worktree_verify_status() {
    local worktree_status=$(git s --short)
    if [ -n "$worktree_status" ]; then
        echo "Warning: Worktree has uncommitted changes:"
        echo "$worktree_status"
    fi
}

# === Public functions ===
function git-worktree-new() {
    if [ -z "$1" ]; then
        echo "Usage: git-worktree-new BRANCH_NAME"
        echo ""
        echo "Creates a new git worktree with automatic git-crypt support."
        echo "Worktrees are created in .worktrees/ directory."
        return 1
    fi

    local branch_name="$1"
    local repo_root=$(_git_worktree_init) || return 1
    local worktree_path=$(_git_worktree_get_path "$repo_root" "$branch_name")

    echo "Creating worktree for branch: $branch_name"
    echo "Location: $worktree_path"

    _git_worktree_create_and_enter "$repo_root" "$worktree_path" "$branch_name" -b "$branch_name"
    _git_worktree_verify_status

    echo ""
    echo "✓ Worktree created successfully"
}

function git-worktree-pr() {
    if [ -z "$1" ]; then
        echo "Usage: git-worktree-pr PR_NUMBER"
        echo ""
        echo "Checks out a GitHub PR for review in an isolated worktree."
        echo "Automatically handles git-crypt if present."
        return 1
    fi

    local pr_number="$1"
    local repo_root=$(_git_worktree_init) || return 1

    # Get PR branch name from GitHub
    local pr_branch=$(gh pr view "$pr_number" --json headRefName -q .headRefName 2>/dev/null)
    local branch_name="$pr_branch"
    local worktree_dir_name="pr-$pr_number-$pr_branch"

    local worktree_path=$(_git_worktree_get_path "$repo_root" "$worktree_dir_name")

    echo "Fetching PR #$pr_number..."
    git fetch origin "pull/$pr_number/head:$branch_name" 2>&1 | grep -v "^From" || true

    echo "Creating worktree for PR #$pr_number..."

    _git_worktree_create_and_enter "$repo_root" "$worktree_path" "$branch_name" "$branch_name"
    _git_worktree_verify_status

    echo ""
    echo "✓ PR #$pr_number checked out successfully"
    echo "Location: $worktree_path"
}

function git-worktree-prune() {
    if [ -z "$1" ]; then
        echo "Usage: git-worktree-prune BRANCH_NAME"
        echo ""
        echo "Removes a git worktree and deletes its branch."
        echo ""
        echo "This will:"
        echo "  1. Remove the worktree directory"
        echo "  2. Delete the branch (using -D to force delete)"
        return 1
    fi

    local branch_name="$1"
    local repo_root=$(_git_worktree_init) || return 1
    local worktree_path="$repo_root/.worktrees/$branch_name"

    if [ ! -d "$worktree_path" ]; then
        echo "Error: Could not find worktree for branch '$branch_name'"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
    fi

    echo "Removing worktree: $worktree_path"
    if git worktree remove "$worktree_path" --force; then
        echo "✓ Worktree removed"
    else
        return 1
    fi

    # Delete the branch
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Deleting branch: $branch_name"
        if git br -D "$branch_name"; then
            echo "✓ Branch deleted"
        fi
    fi
}

function git-worktree-cd() {
    if [ -z "$1" ]; then
        echo "Usage: git-worktree-cd BRANCH_NAME"
        echo ""
        echo "Changes directory into the specified git worktree."
        return 1
    fi

    local branch_name="$1"
    local repo_root=$(_git_worktree_init) || return 1
    local worktree_path="$repo_root/.worktrees/$branch_name"

    if [ ! -d "$worktree_path" ]; then
        echo "Error: Could not find worktree for branch '$branch_name'"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
    fi

    cd "$worktree_path"
}

# === Completions ===
function _git-worktree-prune() {
    local repo_root=$(git root 2>/dev/null)
    if [ -n "$repo_root" ] && [ -d "$repo_root/.worktrees" ]; then
        local -a branches
        branches=(${repo_root}/.worktrees/*(/:t))
        _describe 'worktree branch' branches
    fi
}
compdef _git-worktree-prune git-worktree-prune
compdef _git-worktree-prune git-worktree-cd

function _git-worktree-pr() {
    local -a prs
    local pr_list=$(gh pr list --limit 50 --json number,title --jq '.[] | "\(.number):\(.title)"' 2>/dev/null)
    if [ -n "$pr_list" ]; then
        while IFS= read -r line; do
            prs+=("$line")
        done <<< "$pr_list"
        _describe 'pull request' prs
    fi
}
compdef _git-worktree-pr git-worktree-pr

# Aliases
alias gwnew='git-worktree-new'
alias gwpr='git-worktree-pr'
alias gwcd='git-worktree-cd'
alias gwprune='git-worktree-prune'
