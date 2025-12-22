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
      default_mode = "locked";
      show_startup_tips = false;
      env = {
        # Extra config needs to be injected here to make sure XDG dirs are set for nushell,
        # since nix xdg setup only works for zsh and bash.
        HOME = config.home.homeDirectory;
        XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
        XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
        XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
        XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
        XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin"; # not standard, but useful
      };
    };
    extraConfig = ''
      keybinds {
        locked {
          unbind "Ctrl g"
          bind "Alt ;" { SwitchToMode "Normal"; }
          bind "Alt [" { MoveFocusOrTab "Left"; }
          bind "Alt ]" { MoveFocusOrTab "Right"; }
        }
        shared_except "locked" {
          unbind "Ctrl g"
          bind "Alt ;" { SwitchToMode "Locked"; }
        }
      }
    '';
  };
}
