# FZF integration

# Colors (Catppuccin Mocha)
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4 \
--height 50% \
--layout=reverse"

# Commands
export FZF_DEFAULT_COMMAND="fd --hidden --follow --strip-cwd-prefix"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type directory"
export FZF_ALT_C_OPTS="--preview 'eza -la --color=always {}' --select-1 --exit-0"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --type file"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --select-1 --exit-0"

# fzf-tab completion styles
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-worktree-pr:*' sort false
zstyle ':completion:*:gwpr:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:git-worktree-pr:*' fzf-flags --no-sort
zstyle ':fzf-tab:complete:gwpr:*' fzf-flags --no-sort
zstyle ':fzf-tab:*' switch-group ',' '.'

# Initialize fzf (keybindings and completions)
if command -v fzf >/dev/null 2>&1; then
  zcache_source "fzf/completion.zsh" -- fzf --zsh
fi
