# Git integration (non-worktree)

# Reset repo hooks to personal template
function git_hooks_reset() {
    local repo_root template_hooks hooks_dir initial_hooks_dir timestamp backup_dir

    repo_root=$(command git rev-parse --show-toplevel 2>/dev/null) || repo_root=""
    if [[ -z "$repo_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    template_hooks="$HOME/.config/git/template/hooks"
    initial_hooks_dir=$(command git rev-parse --git-path hooks 2>/dev/null) || initial_hooks_dir=""

    if [[ ! -d "$template_hooks" ]]; then
        echo "Error: Default hooks template directory not found: $template_hooks" >&2
        return 1
    fi

    command git config --unset core.hooksPath >/dev/null 2>&1 || true

    hooks_dir=$(command git rev-parse --git-path hooks 2>/dev/null) || hooks_dir=""
    if [[ -z "$hooks_dir" ]]; then
        hooks_dir="$repo_root/.git/hooks"
    fi

    mkdir -p "$hooks_dir"

    if [[ -n $(find "$hooks_dir" -maxdepth 1 -type f -print -quit 2>/dev/null) ]]; then
        timestamp=$(date +"%Y%m%d%H%M%S")
        backup_dir="$hooks_dir/reset-backup-$timestamp"
        mkdir -p "$backup_dir"
        find "$hooks_dir" -maxdepth 1 -type f -exec cp {} "$backup_dir/" \;
        echo "🗃  Existing hooks backed up to $backup_dir"
    fi

    for hook_file in "$template_hooks"/*; do
        [[ -f "$hook_file" ]] || continue
        cp "$hook_file" "$hooks_dir/"
        chmod +x "$hooks_dir/$(basename "$hook_file")"
    done

    echo "✅ Hooks reset using $template_hooks"
}

# Aliases
alias gsw="git sw"
alias git-hooks-reset="git_hooks_reset"
