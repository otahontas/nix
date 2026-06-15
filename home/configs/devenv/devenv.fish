# devenv shell respects $SHELL — make sure it's fish
set -gx SHELL (which fish)

# Auto-activate devenv shell when entering a project
function __devenv_auto --on-variable PWD
    if test -f "$PWD/devenv.nix"; and not set -q IN_NIX_SHELL
        devenv shell
    end
end
