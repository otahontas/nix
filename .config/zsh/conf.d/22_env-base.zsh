# Base environment variables (XDG, history files, etc.)

# Note: XDG_DATA_HOME, XDG_CONFIG_HOME, XDG_CACHE_HOME are set in ~/.zshenv
# which loads before .zshrc

# Less
export LESSHISTFILE="$XDG_DATA_HOME/less_history"

# SQLite
export SQLITE_HISTORY="$XDG_DATA_HOME/sqlite_history"

# Node
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# Rust
export RUSTUP_HOME="$XDG_CACHE_HOME/rustup"
export CARGO_HOME="$XDG_CACHE_HOME/cargo"

# Volta
export VOLTA_FEATURE_PNPM=1

# Git Hooks
export HUSKY=0  # Disable husky - use own hooks from ~/.config/git/template/hooks

# GPG
export GPG_TTY="$(tty)"

# SSH (1Password as agent)
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Prompt
export SHOW_AWS_PROMPT="false"
