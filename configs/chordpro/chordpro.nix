{ pkgs, ... }:
{
  home.packages = with pkgs; [
    perlPackages.AppMusicChordPro
  ];
}
