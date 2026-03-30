{
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = [ (lib.lowPrio pkgs.docker-credential-helpers) ];
    file.".docker/config.json".source = ./config.json;
  };
}
