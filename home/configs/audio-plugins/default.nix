{ pkgs, ... }:
{
  home.packages = [
    pkgs.brewCasks.arturia-software-center
    pkgs.brewCasks.waves-central
    pkgs.brewCasks.native-access
  ];
}
