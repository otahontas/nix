# Default recipe - does nothing
default:

# Apply nix-darwin configuration (requires sudo)
apply: verify
    sudo darwin-rebuild switch --flake ~/.config/nix-darwin

# Check flake configuration
check-flake:
    nix flake check

# Run all formatters in parallel
[parallel]
format: format-nix format-nvim

# Format Nix files
format-nix:
    fd -e nix -x nixfmt

# Format nvim lua files
format-nvim:
    just configs/home/neovim/nvim/format

# Run all linters in parallel (format runs first)
lint: format _lint-tasks

[parallel]
[private]
_lint-tasks: lint-nu lint-nvim

# Lint nvim lua files
lint-nvim:
    just configs/home/neovim/nvim/lint

# Lint all Nushell files
lint-nu:
    for f in configs/home/**/*.nu; do nu -c "source $f" || exit 1; done

# Verify config
verify: lint check-flake
    darwin-rebuild build --flake ~/.config/nix-darwin
