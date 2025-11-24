{ pkgs, config, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
  };

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
