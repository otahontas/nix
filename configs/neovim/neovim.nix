{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      nixd
      tree-sitter
    ];
  };
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
