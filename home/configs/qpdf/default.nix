{ pkgs, ... }:
{
  home.packages = [ pkgs.qpdf ];
  programs.fish.interactiveShellInit = builtins.readFile ./config.fish;
}
