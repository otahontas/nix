{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    # lower priority so orbstack's docker-credential-osxkeychain wins
    packages = [ (lib.lowPrio pkgs.docker-credential-helpers) ];
    file.".docker/config.json".source = ./config.json;
    # obrstack is installed through homebrew but needs to added to path anyways
    sessionPath = [ "$HOME/.orbstack/bin" ];
    # point docker vars to orbstack so testcontainers works properly
    sessionVariables = {
      DOCKER_HOST = "unix://${config.home.homeDirectory}/.orbstack/run/docker.sock";
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
    };
  };
}
