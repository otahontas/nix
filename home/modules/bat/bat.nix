{ ... }:
{
  catppuccin.bat.enable = true;
  programs.bat.enable = true;
  programs.nushell.shellAliases = {
    cat = "bat";
  };
}
