{ ... }:
{
  catppuccin.skim.enable = true;
  programs.skim = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
}
