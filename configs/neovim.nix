{ pkgs, config, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Set as default editor
    defaultEditor = true;
  };

  # Deploy nvim config from nix-darwin repo to ~/.config/nvim
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
