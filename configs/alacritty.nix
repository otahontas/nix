{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell.program = "${pkgs.zellij}/bin/zellij";

      font = {
        normal = { family = "VictorMono Nerd Font"; style = "Regular"; };
        size = 13.75;
      };

      window.decorations = "Transparent";

      # Olympia theme
      colors = {
        primary = {
          background = "#dbd6cb"; # TVT H615 - harm.valkoinen
          foreground = "#545554"; # TVT H766 - musta
        };

        cursor = {
          cursor = "#a07647"; # TVT H708 - tammi
          text = "#dbd6cb";
        };

        vi_mode_cursor = {
          cursor = "#a07647";
          text = "#dbd6cb";
        };

        selection = {
          background = "#e8ce93"; # TVT H626 - keltainen
          text = "#545554";
        };

        search = {
          matches = {
            background = "#dfbd93"; # TVT H637 - keltainen
            foreground = "#545554";
          };
          focused_match = {
            background = "#a07647"; # TVT H708 - tammi
            foreground = "#e9e2d1"; # TVT H679 - valkoinen
          };
        };

        hints = {
          start = {
            background = "#a07647";
            foreground = "#e9e2d1";
          };
          end = {
            background = "#835f43"; # TVT H707 - rusk.kuulto
            foreground = "#e9e2d1";
          };
        };

        # Normal colors (ANSI 0-7)
        normal = {
          black   = "#545554"; # TVT H766 - musta
          red     = "#754742"; # TVT H771 - punainen
          green   = "#747362"; # TVT H714 - harm.vihreä
          yellow  = "#a07647"; # TVT H708 - tammi
          blue    = "#8c9187"; # TVT H767 - harmaa
          magenta = "#765c49"; # TVT H763 - ruskea
          cyan    = "#7f796c"; # TVT H605 - harmaa
          white   = "#e9e2d1"; # TVT H679 - valkoinen
        };

        # Bright colors (ANSI 8-15)
        bright = {
          black   = "#9f9c91"; # TVT H603 - harmaa
          red     = "#d3afa1"; # TVT H701 - vaal.punainen
          green   = "#bac4b1"; # TVT H762 - vihreä
          yellow  = "#e8ce93"; # TVT H626 - keltainen
          blue    = "#a5a893"; # TVT H696 - harm.vihreä
          magenta = "#d8b79b"; # TVT H639 - kelt.roosa
          cyan    = "#cfc0ab"; # TVT H690 - rusk.harmaa
          white   = "#e9e2d1"; # TVT H679 - valkoinen
        };

        # Dim colors
        dim = {
          black   = "#464443"; # TVT H723 - rusk.musta
          red     = "#5d4a47";
          green   = "#5a5950";
          yellow  = "#7f5c38";
          blue    = "#6e726b";
          magenta = "#5d4a3b";
          cyan    = "#635d56";
          white   = "#c5c6bc"; # TVT H613 - vaal.harmaa
        };
      };

      keyboard.bindings = [
        { key = "C"; mods = "Alt"; chars = "\\u001bc"; }
      ];
    };
  };
}
