{ pkgs, config, ... }:
let
  homeDir = config.home.homeDirectory;
  findApps = ''find -L /Applications -maxdepth 2 -name "*.app" 2>/dev/null; find -L ${homeDir}/Applications -maxdepth 3 -name "*.app" 2>/dev/null'';
  formatApps = ''sed "s|.*/||;s|\.app\$||" | sort -u'';
  launchApp = ''${pkgs.choose-gui}/bin/choose | xargs -I{} open -a "{}"'';
in
{
  home.packages = with pkgs; [
    skhd
    choose-gui
    less
    coreutils
  ];

  home.file.".skhdrc".text = ''
    # App launcher
    cmd - space : sh -c '(${findApps}) | ${formatApps} | ${launchApp}'

    # Screenshot area to clipboard
    shift + ctrl + alt + cmd - p : screencapture -i -c
  '';

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
