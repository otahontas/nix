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

      window.decorations = "Transparent";
      window.startup_mode = "Fullscreen";
      window.option_as_alt = "OnlyLeft";

      mouse.hide_when_typing = true;

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
