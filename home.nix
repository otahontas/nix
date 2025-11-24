{ pkgs, lib, ... }:
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

  # Enable XDG base directory management (sets XDG_CONFIG_HOME, XDG_CACHE_HOME, XDG_DATA_HOME)
  xdg.enable = true;

  # Default editor fallback (overridden by neovim when installed)
  home.sessionVariables = {
    VISUAL = lib.mkDefault "vim";
    EDITOR = lib.mkDefault "vim";
  };
}
