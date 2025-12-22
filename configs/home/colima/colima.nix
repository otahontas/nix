{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    colima
    docker-client
    docker-credential-helpers
  ];
  # TODO: replace with merging config from here (takes precendence) with current .docker/config.json
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

  programs.nushell.environmentVariables = {
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
  };
}
