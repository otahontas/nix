# History configuration
HISTFILE=$XDG_DATA_HOME/zsh/histfile
HISTSIZE=10000
SAVEHIST=$HISTSIZE

# History options
setopt sharehistory
setopt incappendhistory
setopt histexpiredupsfirst
setopt histignoredups
setopt histfindnodups
setopt histreduceblanks
