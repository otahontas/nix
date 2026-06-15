# enable vi mode
fish_vi_key_bindings

# clear screen + scrollback at startup (hides "Last login" after the fact)
set -g fish_greeting
printf '\33c\e[3J'
