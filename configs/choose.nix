{ pkgs, config, ... }:
let
  homeDir = config.home.homeDirectory;
  findApps = ''find -L /Applications -maxdepth 2 -name "*.app" 2>/dev/null; find -L ${homeDir}/Applications -maxdepth 3 -name "*.app" 2>/dev/null'';
  formatApps = ''sed "s|.*/||;s|\.app\$||" | sort -u'';
  launchApp = ''${pkgs.choose-gui}/bin/choose | xargs -I{} open -a "{}"'';
in
{
  home.packages = with pkgs; [
    choose-gui
    skhd
    less
    coreutils
  ];

  home.file.".skhdrc".text = ''
    cmd - space : sh -c '(${findApps}) | ${formatApps} | ${launchApp}'
  '';

  # Launch skhd service
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
