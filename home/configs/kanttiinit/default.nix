{ pkgs, ... }:
let
  kanttiinit = pkgs.callPackage ../../packages/kanttiinit.nix { };
in
{
  home.packages = [ kanttiinit ];
}
