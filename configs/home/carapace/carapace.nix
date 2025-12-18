{ pkgs, ... }:
{
  home.packages = with pkgs; [
    carapace
  ];
}
