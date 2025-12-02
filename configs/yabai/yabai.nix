{ pkgs, ... }:
{
  home.packages = with pkgs; [
    yabai
  ];
  home.file.".yabairc" = {
    source = pkgs.replaceVars ./yabairc.sh {
      yabai_bin = "${pkgs.yabai}/bin/yabai";
    };
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
