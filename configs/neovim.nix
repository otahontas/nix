{ pkgs, config, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  # Deploy nvim config from nix-darwin repo to ~/.config/nvim
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
