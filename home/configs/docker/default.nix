{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    # must install lower priority so orbstack's docker-credential-osxkeychain wins
    # this is needed still so docker + password-store helper works
    packages = [ (lib.lowPrio pkgs.docker-credential-helpers) ];
    file.".docker/config.json".source = ./config.json;
    # point docker vars to orbstack so testcontainers works properly
    sessionVariables = {
      DOCKER_HOST = "unix://${config.home.homeDirectory}/.orbstack/run/docker.sock";
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    };
  };
}
