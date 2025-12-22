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
    extraEnv = ''
      $env.PATH = (
        $env.PATH | split row (char esep)
        | prepend $"($env.HOME)/.local/bin"
        | prepend $"/etc/profiles/per-user/($env.USER)/bin"
        | prepend "/run/current-system/sw/bin"
        | prepend "/nix/var/nix/profiles/default/bin"
        | uniq
      )
    '';
    environmentVariables = {
      SHELL = lib.getExe pkgs.nushell;
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
