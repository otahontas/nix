{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    skhd
    choose-gui
  ];
  home.file.".skhdrc".source = pkgs.replaceVars ./.skhdrc.in {
    home_dir = config.home.homeDirectory;
    choose_bin = "${pkgs.choose-gui}/bin/choose";
  };

  launchd.agents.skhd = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.skhd}/bin/skhd" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
    };
  };
}
