# nix-darwin system configuration
# This module contains all macOS system-level settings
{
  lib,
  self,
  username,
  homeDirectory,
  ...
}:
let
  systemConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
    lib.filesystem.listFilesRecursive ./configs/system
  );
in
{
  imports = systemConfigFiles;

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  system.primaryUser = username;
  users.users.${username}.home = homeDirectory;
}
