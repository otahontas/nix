{ pkgs, ... }:
{
  imports = [
    ./configs/alacritty.nix
    ./configs/claude.nix
    ./configs/neovim.nix
    ./configs/nushell.nix
    ./configs/yazi.nix
    ./configs/zellij.nix
    ./configs/zoxide.nix
  ];

  home.username = "otahontas";
  home.homeDirectory = "/Users/otahontas";
  home.stateVersion = "25.05";

  # Enable XDG base directory management
  xdg.enable = true;
}
