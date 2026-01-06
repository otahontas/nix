# home-manager user configuration
# This module contains all user-level settings and can be used standalone
{
  lib,
  username,
  homeDirectory,
  ...
}:
let
  homeConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
    lib.filesystem.listFilesRecursive ./configs/home
  );
in
{
  imports = homeConfigFiles;

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.05";
  xdg.enable = true;
}
