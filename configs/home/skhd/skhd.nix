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
