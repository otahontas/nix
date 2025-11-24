default:
  @just --list

format:
  nixfmt **/*.nix

build:
  sudo darwin-rebuild switch --flake ~/.config/nix-darwin

check:
  nix flake check
