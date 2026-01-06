{ lib, inputs, ... }:
let
  homeConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
    lib.filesystem.listFilesRecursive ./configs/home
  );
in
{
  imports = homeConfigFiles;

  # Home Manager configuration
  home.stateVersion = "25.05";
  xdg.enable = true;
}
