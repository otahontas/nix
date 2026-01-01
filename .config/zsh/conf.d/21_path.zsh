# PATH configuration - order matters!

# Local bin (highest priority)
export PATH="$HOME/.local/bin:$PATH"

# Homebrew (modified output of `brew shellenv` to avoid running brew on every shell start)
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# Homebrew completions
fpath+="/opt/homebrew/share/zsh/site-functions"

# GNU grep (prefer over macOS grep)
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"

# Go
export GOPATH="$XDG_CACHE_HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# Volta
export VOLTA_HOME="$XDG_CACHE_HOME/volta"
export PATH="$VOLTA_HOME/bin:$PATH"
