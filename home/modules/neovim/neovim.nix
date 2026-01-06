{
  pkgs,
  inputs,
  ...
}:
let
  codeformat = pkgs.stdenv.mkDerivation rec {
    pname = "codeformat";
    version = "1.5.7";
    src = pkgs.fetchzip {
      url = "https://github.com/CppCXY/EmmyLuaCodeStyle/releases/download/${version}/darwin-arm64.tar.gz";
      sha256 = "sha256-wW7xfecXW7l2hisCLo1Q2VdmO/eU8+lGqzdS4M4D9oo=";
      stripRoot = false;
    };
    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp darwin-arm64/bin/CodeFormat $out/bin/
      cp darwin-arm64/lib/*.dylib $out/lib/
      chmod +x $out/bin/CodeFormat
    '';
  };
in
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
      efm-langserver
      emmylua-ls
      nixd
      postgres-language-server
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

  # .luarc.json for emmylua_check (needs VIMRUNTIME path)
  xdg.configFile."nix-darwin/configs/home/neovim/nvim/.luarc.json".source =
    pkgs.replaceVars ./.luarc.json.in
      {
        nvim_runtime = "${pkgs.neovim-unwrapped}/share/nvim/runtime";
      };

  # Editorconfig (neovim is main consumer via built-in editorconfig support)
  # using .editorconfig.in, the file shouldn't be considered as editorconfig in this folder by tools
  home.file.".editorconfig".source = ./.editorconfig.in;

  # Expose select tools to shell (extraPackages only available inside nvim)
  home.packages = [
    # emmylua format & lint (corresponding to emmylua-ls formatting & linting)
    codeformat
    pkgs.emmylua-check

    # nix
    pkgs.nixf-diagnose
    pkgs.nixfmt-rfc-style

    # python
    pkgs.ruff

    # nushell
    inputs.topiary-nushell.packages.aarch64-darwin.default
  ];

  programs.nushell = {
    environmentVariables = {
      VISUAL = "nvim";
      EDITOR = "nvim";
    };
    shellAliases = {
      todo = "nvim ~/Documents/todo/todo.txt";
    };
  };
}
