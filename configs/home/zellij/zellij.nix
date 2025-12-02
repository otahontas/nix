{ pkgs, config, ... }:
{
  catppuccin.zellij.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "${pkgs.nushell}/bin/nu";
      show_startup_tips = false;
    };
    extraConfig = ''
      env {
        HOME "${config.home.homeDirectory}"
        XDG_CONFIG_HOME "${config.home.homeDirectory}/.config"
        XDG_CACHE_HOME "${config.home.homeDirectory}/.cache"
        XDG_DATA_HOME "${config.home.homeDirectory}/.local/share"
      }
    '';
  };
}
