{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gfortran
  ];
}
