{ pkgs, config, ... }:
let
  rose-pine-zellij = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "zellij";
    rev = "f4b7c27f9515d964a78e07da8332530a45f060d5";
    hash = "sha256-eilCRSweo0wk4z6snBWFC67NMVvytfDfJqGWVXg6QRc=";
  };
  themeConfig = builtins.readFile "${rose-pine-zellij}/dist/rose-pine-dawn.kdl";
in
{
  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "${pkgs.nushell}/bin/nu";

      show_startup_tips = false;
      default_mode = "locked";
      theme = "rose-pine-dawn";
    };

    extraConfig = ''
      env {
        HOME "${config.home.homeDirectory}"
        XDG_CONFIG_HOME "${config.home.homeDirectory}/.config"
        XDG_CACHE_HOME "${config.home.homeDirectory}/.cache"
        XDG_DATA_HOME "${config.home.homeDirectory}/.local/share"
      }

      ${themeConfig}
    '';
  };
}
