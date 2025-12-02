{ pkgs, ... }:
{
  catppuccin.alacritty.enable = true;
  programs.alacritty = {
    enable = true;
    settings = {
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
        program = "${pkgs.zellij}/bin/zellij";
        args = [
          "-l"
          "welcome"
        ];
      };
      window.decorations = "Transparent";
      window.startup_mode = "Fullscreen";
      window.option_as_alt = "OnlyLeft";
    };
  };
}
