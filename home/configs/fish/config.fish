# devenv shell respects $SHELL — make sure it's fish
set -gx SHELL (which fish)

# enable vi mode
fish_vi_key_bindings

# clear screen + scrollback at startup (hides "Last login" after the fact)
set -g fish_greeting
printf '\33c\e[3J'

# Auto-activate devenv shell when entering a project
function __devenv_auto --on-variable PWD
    if test -f "$PWD/devenv.nix"; and not set -q IN_NIX_SHELL
        devenv shell
    end
end
