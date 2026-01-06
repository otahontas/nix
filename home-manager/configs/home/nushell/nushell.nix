{
  pkgs,
  lib,
  ...
}:
{
  catppuccin.nushell.enable = true;
  programs.nushell = {
    enable = true;
    extraConfig = builtins.readFile ./config.nu;
    extraEnv = builtins.readFile ./env.nu;
    environmentVariables = {
      SHELL = lib.getExe pkgs.nushell;
    };
    shellAliases = {
      la = "ls -a";
      ll = "ls -l";
      lla = "ls -la";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };
    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        algorithm = "fuzzy";
        quick = true;
        partial = true;
        use_ls_colors = true;
      };
      history = {
        max_size = 10000;
        sync_on_enter = true;
        file_format = "sqlite";
        isolation = false;
      };
      cursor_shape = {
        vi_insert = "line";
        vi_normal = "block";
      };
    };
  };
}
