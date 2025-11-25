{ pkgs, config, ... }:
let
  rose-pine-alacritty = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "alacritty";
    rev = "a6f7c8245e5bba639befe52e1e025f84ba8b3ee5";
    hash = "sha256-eVQjH5TrMLP9FdxIovnH9ulxTr6uw82Dt8PGGvpF94k=";
  };
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [ "${rose-pine-alacritty}/dist/rose-pine-dawn.toml" ];

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
