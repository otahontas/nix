{ pkgs, config, ... }:
{
  catppuccin.alacritty.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {

      terminal.shell = {
        program = "${pkgs.zellij}/bin/zellij";
        args = [
          "-l"
          "welcome"
        ];
      };

      font = {
        normal = {
          family = "VictorMono Nerd Font";
          style = "Medium";
        };
        bold = {
          family = "VictorMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "VictorMono Nerd Font";
          style = "Regular Italic";
        };
        size = 14;
      };

      window.decorations = "Transparent";
      window.startup_mode = "Fullscreen";
      window.option_as_alt = "OnlyLeft";

      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = "\\u001b[13;2u";
        }
      ];
    };
  };
}
