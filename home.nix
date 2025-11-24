{ pkgs, ... }:
{
  imports = [
    ./configs/alacritty.nix
    ./configs/zellij.nix
    ./configs/nushell.nix
    ./configs/yazi.nix
    ./configs/zoxide.nix
  ];

  home.username = "otahontas";
  home.homeDirectory = "/Users/otahontas";
  home.stateVersion = "25.05";
}
