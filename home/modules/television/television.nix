{ ... }:
{
  catppuccin.television.enable = true;
  programs.television.enable = true;
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
  xdg.configFile."television/cable" = {
    source = ./cable;
    recursive = true;
  };
}
