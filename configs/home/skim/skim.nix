{ ... }:
{
  catppuccin.skim.enable = true;
  programs.skim = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };
  # Keybindings replaced by television - see configs/home/television/
  # programs.nushell.extraConfig = builtins.readFile ./config.nu;
}
