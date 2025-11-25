{ pkgs, lib, ... }:
{
  imports = [
    ./configs/alacritty.nix
    ./configs/bat.nix
    ./configs/choose.nix
    ./configs/claude.nix
    ./configs/colima.nix
    ./configs/delta.nix
    ./configs/gh.nix
    ./configs/git.nix
    ./configs/cli-tools.nix
    ./configs/just.nix
    ./configs/local-scripts.nix
    ./configs/neovim.nix
    ./configs/nixfmt.nix
    ./configs/nushell.nix
    ./configs/starship.nix
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
