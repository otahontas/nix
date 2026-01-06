set shell := ["nu", "-c"]

default:

[parallel]
format: format-nix format-nu format-nvim

format-nix:
  nixfmt ...(glob **/*.nix)

format-nu:
  topiary-nushell format ...(glob **/*.nu)

format-nvim:
  just home-manager/configs/home/neovim/nvim/format

lint: format _lint-tasks # hack: run format sequentially before running all linters in parallel

[parallel]
[private]
_lint-tasks: lint-nix lint-nu lint-nvim

lint-nix:
    nixf-diagnose ...(glob **/*.nix)

lint-nu:
    glob home-manager/configs/home/**/*.nu | each { |f| nu -c $"source ($f)" } | ignore

lint-nvim:
    just home-manager/configs/home/neovim/nvim/lint

# Check both flakes
check-flake:
    nix flake check
    cd home-manager && nix flake check

# System-level verification and application (requires sudo)
verify-darwin: lint
    darwin-rebuild build --flake ~/.config/nix-darwin

apply-darwin: verify-darwin
    sudo darwin-rebuild switch --flake ~/.config/nix-darwin

# User-level application (no sudo)
apply-home:
    cd home-manager && home-manager switch --flake .#otahontas

# Apply both (system then user)
apply: apply-darwin apply-home

update-codeformat:
    just home-manager/configs/home/neovim/nvim/update-codeformat

# Update both flakes
update-flake:
    nix flake update
    cd home-manager && nix flake update

update: update-codeformat update-flake

# Clean up unused Nix packages and old generations
clean:
    nix-collect-garbage -d
