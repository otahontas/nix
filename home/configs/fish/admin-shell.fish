set -l term xterm-256color
if set -q TERM
    set term $TERM
end

set -l lang en_US.UTF-8
if set -q LANG
    set lang $LANG
end

/usr/bin/env -i TERM="$term" LANG="$lang" /usr/bin/su -l otahontas-admin
