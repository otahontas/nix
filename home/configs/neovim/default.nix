{ pkgs, ... }:
let
  todoScript = builtins.readFile ./scripts/todo.sh;
  dailyScript = builtins.readFile ./scripts/daily.sh;
  grealpathForNeovim = pkgs.writeShellScriptBin "grealpath" ''
    exec ${pkgs.coreutils}/bin/realpath "$@"
  '';
in
{
  xdg.configFile = {
    "nvim/filetype.lua".source = ./nvim/filetype.lua;
    "nvim/lua".source = ./nvim/lua;
    "nvim/plugin".source = ./nvim/plugin;
    "nvim/after".source = ./nvim/after;
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withRuby = false;
      withPython3 = false;
      autowrapRuntimeDeps = true;
      initLua = builtins.readFile ./nvim/init.lua;
      extraPackages = with pkgs; [
        tree-sitter
        grealpathForNeovim
      ];
      plugins = with pkgs.vimPlugins; [
        # Completion & snippets
        blink-cmp
        copilot-lua
        friendly-snippets

        # Editor enhancements
        hardtime-nvim
        mini-nvim

        # File management
        plenary-nvim # dependency for yazi and others
        yazi-nvim

        # LSP & language support
        nvim-lint
        nvim-lspconfig
        SchemaStore-nvim
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects

        # Fuzzy finding
        fzf-lua

        # Markdown
        markview-nvim

        # Note: catppuccin is auto-installed, so not included here
      ];
    };
  };

  home = {
    packages = [
      (pkgs.writeShellScriptBin "todo_path" todoScript)
      (pkgs.writeShellScriptBin "todo" todoScript)
      (pkgs.writeShellScriptBin "daily_path" dailyScript)
      (pkgs.writeShellScriptBin "daily" dailyScript)
    ];

    sessionVariables = {
      TODO_FILE_LOCATION = "$HOME/Documents/todo/todo.txt";
      DAILY_FOLDER_LOCATION = "$HOME/Documents/journal/daily";
    };
  };
}
