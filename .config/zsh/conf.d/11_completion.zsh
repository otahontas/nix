# Completion system
# Lazy load - only regenerate compdump once per day
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qNmh+24) ]]; then
  compinit
else
  compinit -C
fi
autoload bashcompinit && bashcompinit

# Completion options
setopt correct
setopt no_list_ambiguous
setopt globdots

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion::complete:*' gain-privileges 1
zstyle :compinstall filename '$ZDOTDIR/.zshrc'
