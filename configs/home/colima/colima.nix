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
  home.activation.dockerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.docker
    if [ ! -f ~/.docker/config.json ]; then
      echo '${
        builtins.toJSON {
          credsStore = "pass";
          currentContext = "colima";
        }
      }' > ~/.docker/config.json
    fi
  '';
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
