{ pkgs, ... }:
{
  home.packages = with pkgs; [
    qpdf
  ];
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
}
