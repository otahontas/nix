set -l term xterm-256color
if set -q TERM
    set term $TERM
end

set -l lang en_US.UTF-8
if set -q LANG
    set lang $LANG
end

set -l root $DEVENV_ROOT
if test -z "$root"
    set root (command git rev-parse --show-toplevel 2>/dev/null)
end
if test -n "$root"
    echo $root >/tmp/admin-shell-repo-root
end

/usr/bin/env -i TERM="$term" LANG="$lang" /usr/bin/su -l otahontas-admin
