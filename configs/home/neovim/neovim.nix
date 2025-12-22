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

  # TODO: replace with just replacing neovim-unwrapped pkg binary path + external .luarc.json.in file
  # Generate .luarc.json in source dir for emmylua_check (needs VIMRUNTIME path)
  home.activation.generateLuarc = ''
        cat > ~/.config/nix-darwin/configs/home/neovim/nvim/.luarc.json << 'EOF'
    ${builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json";
      runtime.version = "LuaJIT";
      workspace.library = [ "${pkgs.neovim-unwrapped}/share/nvim/runtime" ];
    }}
    EOF
  '';

  # Editorconfig (neovim is main consumer via built-in editorconfig support)
  # TODO: replace with .editorconfig.in from this folder
  home.file.".editorconfig".text = ''
    root = true

    [*]
    trim_trailing_whitespace = true
  '';

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
    extraConfig = builtins.readFile ./config.nu;
    environmentVariables = {
      VISUAL = "nvim";
      EDITOR = "nvim";
    };
  };
}
