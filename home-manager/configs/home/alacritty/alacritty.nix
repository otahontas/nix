{
  pkgs,
  lib,
  config,
  ...
}:
{
  catppuccin.alacritty.enable = true;
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        # XDG environment variables for Nushell.
        # Nix's xdg setup only works for zsh and bash, so we need to set these manually.
        HOME = config.home.homeDirectory;
        XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
        XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
        XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
        XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
        XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin"; # not standard, but useful
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 14;
      };
      terminal.shell = {
        program = lib.getExe pkgs.nushell;
      };
      window.decorations = "Transparent";
      window.startup_mode = "Fullscreen";
      window.option_as_alt = "OnlyLeft";
    };
  };
}
