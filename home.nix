{ pkgs, lib, ... }:
{
  imports = [
    ./configs/alacritty.nix
    ./configs/claude.nix
    ./configs/delta.nix
    ./configs/gh.nix
    ./configs/git.nix
    ./configs/just.nix
    ./configs/neovim.nix
    ./configs/nixfmt.nix
    ./configs/nushell.nix
    ./configs/vivid.nix
    ./configs/yazi.nix
    ./configs/zellij.nix
    ./configs/zoxide.nix
  ];

  home.username = "otahontas";
  home.homeDirectory = "/Users/otahontas";
  home.stateVersion = "25.05";

  xdg.enable = true;

  home.sessionVariables = {
    VISUAL = lib.mkDefault "vim";
    EDITOR = lib.mkDefault "vim";
  };
}
