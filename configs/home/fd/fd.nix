{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fd
  ];
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
}
