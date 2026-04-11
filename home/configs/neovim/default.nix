{ pkgs, ... }:
let
  treesitterFiletypes = pkgs.writeText "treesitter-filetypes.lua" (
    let
      names = builtins.attrNames pkgs.vimPlugins.nvim-treesitter-parsers;
      body = builtins.concatStringsSep "\n" (map (name: "  \"${name}\",") names);
    in
    ''
      return {
      ${body}
      }
    ''
  );

  treesitterFiletypesDir = pkgs.runCommand "treesitter-lua-dir" { } ''
    mkdir -p $out
    cp ${treesitterFiletypes} $out/treesitter_filetypes.lua
  '';

  treesitterLuaDir = pkgs.symlinkJoin {
    name = "nvim-lua";
    paths = [
      ./nvim/lua
      treesitterFiletypesDir
    ];
  };

  puppeteerConfig = pkgs.writeText "puppeteer-config.json" (
    builtins.toJSON {
      executablePath = "${pkgs.google-chrome}/bin/google-chrome-stable";
      args = [ "--no-sandbox" ];
    }
  );

  todo_path = pkgs.writeShellScriptBin "todo_path" ''
    if [ -z "$TODO_FILE_LOCATION" ]; then
      echo "Error: TODO_FILE_LOCATION environment variable not set" >&2
      exit 1
    fi
    echo "$TODO_FILE_LOCATION"
  '';

  daily_path = pkgs.writeShellScriptBin "daily_path" ''
    if [ -z "$DAILY_FOLDER_LOCATION" ]; then
      echo "Error: DAILY_FOLDER_LOCATION environment variable not set" >&2
      exit 1
    fi

    today=$(date "+%F")
    daily_file="$DAILY_FOLDER_LOCATION/$today.md"
    template_file="$DAILY_FOLDER_LOCATION/daily_template.txt"

    if [ ! -e "$daily_file" ]; then
      if [ ! -e "$template_file" ]; then
        echo "Error: daily template not found at $template_file" >&2
        exit 1
      fi
      sed "s/<YYYY-MM-DD>/$today/g" "$template_file" > "$daily_file"
    fi

    echo "$daily_file"
  '';

  todo = pkgs.writeShellScriptBin "todo" ''
    p=$(todo_path) || exit 1
    nvim "$p"
  '';

  daily = pkgs.writeShellScriptBin "daily" ''
    p=$(daily_path) || exit 1
    nvim "$p"
  '';
in
{
  xdg.configFile = {
    # Note: "nvim/lua" is sourced as a directory, so avoid adding
    # "nvim/lua/treesitter_filetypes.lua" via xdg.configFile.text, which
    # would conflict with this directory mapping.
    "nvim/filetype.lua".source = ./nvim/filetype.lua;
    "nvim/lua".source = treesitterLuaDir;
    "nvim/plugin".source = ./nvim/plugin;
    "nvim/after".source = ./nvim/after;
    "nvim/puppeteer-config.json".source = puppeteerConfig;
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      autowrapRuntimeDeps = true;
      initLua = builtins.readFile ./nvim/init.lua;
      extraPackages = with pkgs; [
        imagemagick
        mermaid-cli
        google-chrome
      ];
      plugins = with pkgs.vimPlugins; [
        # Completion & snippets
        blink-cmp
        friendly-snippets

        # Editor enhancements
        hardtime-nvim
        mini-nvim

        # File management
        plenary-nvim # dependency for yazi and others
        yazi-nvim

        # LSP & language support
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects

        # Fuzzy finding
        fzf-lua

        # Markdown
        markview-nvim
        image-nvim
        diagram-nvim

        # Note: catppuccin is auto-installed, so not included here
      ];
    };
  };

  home = {
    packages = [ todo_path daily_path todo daily ];

    sessionVariables = {
      TODO_FILE_LOCATION = "$HOME/Documents/todo/todo.txt";
      DAILY_FOLDER_LOCATION = "$HOME/Documents/journal/daily";
    };
  };
}
