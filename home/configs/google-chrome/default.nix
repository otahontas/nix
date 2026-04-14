{ pkgs, ... }:
{
  home.packages = [ pkgs.google-chrome ];
}

# TODO: add a link from system to home manager google chrome so tools can find the proper installation
# See the current setup / state of the system.
