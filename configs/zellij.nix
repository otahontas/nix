{ pkgs, config, ... }:
{
  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "${pkgs.nushell}/bin/nu";

      show_startup_tips = false;
      default_mode = "locked";
      theme = "olympia";
    };

    extraConfig = ''
      env {
        HOME "${config.home.homeDirectory}"
        XDG_CONFIG_HOME "${config.home.homeDirectory}/.config"
        XDG_CACHE_HOME "${config.home.homeDirectory}/.cache"
        XDG_DATA_HOME "${config.home.homeDirectory}/.local/share"
      }

      themes {
        olympia {
          fg 245 240 230
          bg 219 214 203
          black 40 40 40
          red 100 50 45
          green 90 100 70
          yellow 140 95 55
          blue 100 110 95
          magenta 95 70 55
          cyan 100 95 85
          white 245 240 230
          orange 115 80 50
        }
      }
    '';
  };
}
