{ pkgs, ... }:
{
  home.packages = with pkgs; [
    carapace
  ];

  programs.nushell.environmentVariables = {
    CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
    CARAPACE_MATCH = "1";
  };
}
