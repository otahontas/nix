{ pkgs, config, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    extraPackages = with pkgs; [
      tree-sitter
    ];
    extraWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${config.home.homeDirectory}/.local/share/mise/installs/node/latest/bin"
    ];
  };

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
