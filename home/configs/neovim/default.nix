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

    # .luarc.json for emmylua_ls (needs VIMRUNTIME path)
    "nvim/.luarc.json".source = pkgs.replaceVars ./.luarc.json.in {
      nvim_runtime = "${pkgs.neovim-unwrapped}/share/nvim/runtime";
    };
  };

  programs = {
    fish = {
      interactiveShellInit = builtins.readFile ./config.fish;

      functions = {
        todo_path = {
          description = "Print TODO file path";
          body = builtins.readFile ./todo_path_function_body.fish;
        };

        daily_path = {
          description = "Create/get today's daily note path";
          body = builtins.readFile ./daily_path_function_body.fish;
        };
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      autowrapRuntimeDeps = true;
      extraLuaConfig = builtins.readFile ./nvim/init.lua;
      extraPackages = with pkgs; [
        # LSP servers
        basedpyright
        bash-language-server
        efm-langserver
        emmylua-ls
        nixd
        postgres-language-server
        typescript-language-server
        vscode-langservers-extracted # eslint, jsonls
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

        # Git integration
        octo-nvim

        # AI assistance
        copilot-lua

        # Markdown
        markview-nvim

        # Note: catppuccin is auto-installed, so not included here
        # Note: The following plugins are not available in nixpkgs:
        #   - unnest-nvim (brianhuster/unnest.nvim)
        #   - ts-error-translator-nvim (dmmulroy/ts-error-translator.nvim)
        #   - twoslash-queries-nvim (marilari88/twoslash-queries.nvim)
      ];
    };
  };

  # Editorconfig (neovim is main consumer via built-in editorconfig support)
  # using .editorconfig.in, the file shouldn't be considered as editorconfig in this folder by tools
  # Language tools (formatters, linters, diagnostics)
  home = {
    file.".editorconfig".source = ./.editorconfig.in;
    packages = with pkgs; [
      # Lua
      stylua
      emmylua-check

      # Nix
      nixf-diagnose
      nixfmt-rfc-style

      # Python
      ruff
    ];
    sessionVariables = {
      TODO_FILE_LOCATION = "$HOME/Documents/todo/todo.txt";
      DAILY_FOLDER_LOCATION = "$HOME/Documents/journal/daily";
    };
  };
}
