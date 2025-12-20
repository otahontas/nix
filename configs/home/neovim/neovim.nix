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
      # LSP servers
      basedpyright
      bash-language-server
      emmylua-ls
      nixd
      postgres-language-server
      ruff
      typescript-language-server
      vscode-langservers-extracted # eslint, jsonls

      # Runtime dependencies
      nodejs_24
      tree-sitter
    ];
  };
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
