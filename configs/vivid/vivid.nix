{ pkgs, ... }:
{
  catppuccin.vivid.enable = true;

  programs.vivid.enable = true;

  programs.nushell.extraEnv = ''
    $env.LS_COLORS = (${pkgs.vivid}/bin/vivid generate catppuccin-latte)
  '';
}
