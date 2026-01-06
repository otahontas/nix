set shell := ["nu", "-c"]

default:

[parallel]
format: format-nix format-nu format-nvim

format-nix:
  nixfmt ...(glob **/*.nix)

format-nu:
  topiary-nushell format ...(glob **/*.nu)

format-nvim:
  just home/modules/neovim/nvim/format

lint: format _lint-tasks # hack: run format sequentially before running all linters in parallel

[parallel]
[private]
_lint-tasks: lint-nix lint-nu lint-nvim

lint-nix:
    nixf-diagnose ...(glob **/*.nix)

lint-nu:
    glob home/modules/**/*.nu | each { |f| nu -c $"source ($f)" } | ignore

lint-nvim:
    just home/modules/neovim/nvim/lint

# Check home-manager flake
check-home:
    cd home && nix flake check

# Check nix-darwin flake  
check-darwin:
    cd darwin && nix flake check

check-flake: check-home check-darwin

# Apply home-manager configuration (no sudo)
apply-home:
    home-manager switch --flake ./home

# Build nix-darwin configuration
verify: lint check-flake
    darwin-rebuild build --flake ./darwin

# Apply nix-darwin configuration (requires sudo)
apply: verify
    sudo darwin-rebuild switch --flake ./darwin

update-codeformat:
    just home/modules/neovim/nvim/update-codeformat

# Update home-manager flake
update-home:
    cd home && nix flake update

# Update nix-darwin flake
update-darwin:
    cd darwin && nix flake update

update-flake: update-home update-darwin

update: update-codeformat update-flake

# Clean up unused Nix packages and old generations
clean:
    nix-collect-garbage -d
