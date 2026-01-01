# Note: This file is always sourced.
# Set XDG Base Directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share

# Always load zsh from config folder
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# Set up visual and editor
export VISUAL=nvim
export EDITOR=$VISUAL

# Lang stuff
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US
export LC_MONETARY=en_FI.UTF-8
export LC_TIME=en_FI.UTF-8
