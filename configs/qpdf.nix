{ pkgs, ... }:
{
  home.packages = with pkgs; [
    qpdf
  ];
}
