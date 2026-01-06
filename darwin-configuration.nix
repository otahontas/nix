{ lib, inputs, ... }:
let
  systemConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
    lib.filesystem.listFilesRecursive ./configs/system
  );
in
{
  imports = systemConfigFiles;

  # System state version
  system.stateVersion = 6;
}
