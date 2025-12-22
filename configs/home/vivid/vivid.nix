{ pkgs, lib, ... }:
{
  catppuccin.vivid.enable = true;
  programs.vivid.enable = true;
  programs.nushell.extraEnv = ''
    $env.LS_COLORS = (${lib.getExe pkgs.vivid} generate catppuccin-latte)
  '';
}
