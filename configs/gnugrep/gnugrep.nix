{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnugrep
  ];
}
