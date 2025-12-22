{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    yabai
  ];
  home.file.".yabairc" = {
    source = pkgs.replaceVars ./.yabairc.in {
      yabai_bin = lib.getExe pkgs.yabai;
    };
    executable = true;
  };
  launchd.agents.yabai = {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe pkgs.yabai) ];
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
