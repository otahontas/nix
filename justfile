set shell := ["nu", "-c"]

default:

[parallel]
format: format-nix format-nu format-nvim

format-nix:
  nixfmt ...(glob **/*.nix)

format-nu:
  topiary-nushell format ...(glob **/*.nu)

format-nvim:
  just configs/home/neovim/nvim/format

lint: format _lint-tasks # hack: run format sequentially before running all linters in parallel

[parallel]
[private]
_lint-tasks: lint-nix lint-nu lint-nvim

lint-nix:
    nixf-diagnose ...(glob **/*.nix)

lint-nu:
    glob configs/home/**/*.nu | each { |f| nu -c $"source ($f)" } | ignore

lint-nvim:
    just configs/home/neovim/nvim/lint

check-flake:
    nix flake check

verify: lint check-flake
    darwin-rebuild build --flake ~/.config/nix-darwin

apply: verify
    sudo darwin-rebuild switch --flake ~/.config/nix-darwin

update-codeformat:
    just configs/home/neovim/nvim/update-codeformat

update-flake:
    nix flake update

update: update-codeformat update-flake

# Clean up unused Nix packages and old generations
clean:
    nix-collect-garbage -d
