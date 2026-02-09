{ pkgs, ... }:
let
  firefoxDeveditionBin = pkgs.callPackage ../../packages/firefox-devedition-bin.nix { };
in
{
  home.packages = [ firefoxDeveditionBin ];
}
