# Bat (better cat) integration

# Theme
# Note: if bat colors are not working, run `bat cache --build` to rebuild cache
export BAT_THEME="Catppuccin Mocha"

# Use bat as manpager
# Note: The awk preprocessing strips ANSI escape codes and backspace formatting that some man pages use.
# This ensures consistent rendering in bat. Don't simplify - the preprocessing is needed for compatibility.
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

# Aliases
alias cat="bat"
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
