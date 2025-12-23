{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    skhd
    choose-gui
  ];
  home.file.".skhdrc".source = pkgs.replaceVars ./.skhdrc.in {
    home_dir = config.home.homeDirectory;
    choose_bin = lib.getExe' pkgs.choose-gui "choose";
    yabai_bin = lib.getExe pkgs.yabai;
  };

  launchd.agents.skhd = {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe pkgs.skhd) ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
    };
  };
}
