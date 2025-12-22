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
  home.file.".docker/config.json".source = ./docker-config.json;
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
    NODE_OPTIONS = "--dns-result-order=ipv4first";
  };

  programs.ssh.includes = [ "~/.colima/ssh_config" ];
}
