{ ... }:
{
  catppuccin.bat.enable = true;
  programs.bat.enable = true;
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
}
