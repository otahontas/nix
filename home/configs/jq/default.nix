{ pkgs, ... }:
{
  # jq doesn't have a Home Manager `programs.jq` module; install as a standalone tool.
  home.packages = [ pkgs.jq ];
}
