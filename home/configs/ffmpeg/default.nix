{ pkgs, ... }:
{
  # ffmpeg doesn't have a Home Manager `programs.ffmpeg` module; install as a standalone tool.
  home.packages = [ pkgs.ffmpeg ];
}
