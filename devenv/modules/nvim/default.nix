{
  lib,
  config,
  ...
}:
{
  options.repoDevenv.nvim = {
    extraLsps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
  };

  config =
    let
      baseLsps = [
        "nixd"
        "bashls"
      ];
      baseLines = [
        "vim.cmd([[set runtimepath+=.nvim]])"
      ]
      ++ map (lsp: ''vim.lsp.enable("${lsp}")'') baseLsps;
      extraLines =
        map (lsp: ''vim.lsp.enable("${lsp}")'') config.repoDevenv.nvim.extraLsps
        ++ lib.optional (config.repoDevenv.nvim.extraConfig != "") config.repoDevenv.nvim.extraConfig;
      content =
        "-- ### repo devenv nvim\n"
        + lib.concatStringsSep "\n" baseLines
        + "\n"
        + "-- ### end\n"
        + lib.optionalString (extraLines != [ ]) ("\n" + lib.concatStringsSep "\n" extraLines + "\n");
    in
    {
      files.".nvim.lua".text = content;
    };
}
