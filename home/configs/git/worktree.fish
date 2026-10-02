function git-worktree-new --description "Create a new git worktree with a new branch"
    git-worktree-helper new $argv; or return
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
