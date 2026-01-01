# General zsh options
setopt autocd           # cd without typing cd
setopt extendedglob     # Extended globbing

# Disable r command (replay last command)
disable r

# Prompt
PS1='%F{blue}%~ %(?.%F{green}.%F{red})%#%f '
