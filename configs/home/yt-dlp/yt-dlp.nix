{ pkgs, ... }:
{
  home.packages = with pkgs; [
    yt-dlp
    aria2
  ];

  xdg.configFile."yt-dlp/config".source = ./config;
}
