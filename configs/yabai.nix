{ pkgs, ... }:
{
  home.packages = with pkgs; [
    yabai
  ];

  home.file.".yabairc" = {
    text = ''
      #!/usr/bin/env sh

      # Use full path to yabai for launchd compatibility
      YABAI="${pkgs.yabai}/bin/yabai"

      # TODO: check which options I want to use

      # Ignore specific apps
      $YABAI -m rule --add app="^System Settings$" manage=off
      $YABAI -m rule --add app="^Calculator$" manage=off
      $YABAI -m rule --add app="^Finder$" manage=off
      $YABAI -m rule --add app="^Activity Monitor$" manage=off
      $YABAI -m rule --add app="^1Password$" manage=off
    '';
    executable = true;
  };

  launchd.agents.yabai = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.yabai}/bin/yabai" ];
      EnvironmentVariables = {
        PATH = "${pkgs.yabai}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
      };
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/yabai.out.log";
      StandardErrorPath = "/tmp/yabai.err.log";
    };
  };
}
