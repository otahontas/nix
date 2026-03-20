set -l term xterm-256color
if set -q TERM
    set term $TERM
end

set -l lang en_US.UTF-8
if set -q LANG
    set lang $LANG
end

set -l devenv_root ""
if set -q DEVENV_ROOT
    set devenv_root $DEVENV_ROOT
else
    set devenv_root (command git rev-parse --show-toplevel 2>/dev/null)
end

/usr/bin/env -i TERM="$term" LANG="$lang" DEVENV_ROOT="$devenv_root" /usr/bin/su -l otahontas-admin
