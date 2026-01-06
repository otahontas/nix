{ lib, inputs, ... }:
let
  systemConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
    lib.filesystem.listFilesRecursive ./modules
  );
in
{
  imports = systemConfigFiles;

  # System state version
  system.stateVersion = 6;
}
