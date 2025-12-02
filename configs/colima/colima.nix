{
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    colima
    docker-client
    docker-credential-helpers
  ];
  home.file.".docker/config.json".text = builtins.toJSON {
    credsStore = "pass";
    currentContext = "colima";
  };
  launchd.agents.colima = {
    enable = true;
    config = {
      ProgramArguments = [
        "${lib.getExe pkgs.colima}"
        "start"
        "--foreground"
      ];
      EnvironmentVariables = {
        PATH = "/etc/profiles/per-user/otahontas/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/colima.out.log";
      StandardErrorPath = "/tmp/colima.err.log";
    };
  };
}
