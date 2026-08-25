function __git_pr_branches
    set -l prs (gh pr list --state open --json number,title,author,createdAt,headRefName --limit 50 2>/dev/null)
    if test -z "$prs"
        return
    end

    echo $prs | jq -r '.[] | "\(.headRefName)\t#\(.number) \(.author.login) \(.createdAt | split("T")[0]) \(.title)"'
end

function git-worktree-new --description "Create a new git worktree with a new branch"
    git-worktree-helper new $argv; or return
    set -l path (git-worktree-helper path $argv[1]); or return
    cd "$path"
end

function git-worktree-pr --description "Create a worktree from a GitHub PR branch"
    git-worktree-helper pr $argv; or return
    set -l path (git-worktree-helper path $argv[1]); or return
    cd "$path"
end

function git-worktree-cd --description "Change directory to a git worktree"
    set -l path (git-worktree-helper path $argv[1]); or return
    cd "$path"
end

complete -c git-worktree-cd -f -a "(git-worktree-helper names)"
complete -c git-worktree-new -f -a "(git-worktree-helper names)"
complete -c git-worktree-prune -f -a "(git-worktree-helper names)"
complete -c git-worktree-pr -f -a "(__git_pr_branches)"
