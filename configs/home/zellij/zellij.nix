{
  pkgs,
  lib,
  config,
  ...
}:
{
  catppuccin.zellij.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      default_shell = lib.getExe pkgs.nushell;
      show_startup_tips = false;
    };
    # Extra config needs to be injected here to make sure XDG dirs are set for nushell
    # All the other env vars are set through nushells own config files
    extraConfig = ''
      env {
        HOME "${config.home.homeDirectory}"
        XDG_CACHE_HOME "${config.home.homeDirectory}/.cache"
        XDG_CONFIG_HOME "${config.home.homeDirectory}/.config"
        XDG_DATA_HOME "${config.home.homeDirectory}/.local/share"
      }
    '';
  };
}
