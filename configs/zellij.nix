{ pkgs, ... }:
{
  programs.zellij = {
    enable = true;
    settings = {
      default_shell = "${pkgs.nushell}/bin/nu";

      # Disable tips on startup
      show_startup_tips = false;

      # Start in locked mode - use Ctrl+b (tmux prefix) to access zellij commands
      default_mode = "locked";

      # Use Olympia theme
      theme = "olympia";
    };

    # Olympia theme for Zellij - defined in extraConfig because home-manager
    # themes option doesn't generate the correct KDL wrapper
    # Colors from Helsinki värikaava (Olympiakylä) - adjusted for better contrast
    extraConfig = ''
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
