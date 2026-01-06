{ pkgs, ... }:
{
  home.packages = with pkgs; [
    carapace
  ];

  programs.nushell = {
    extraConfig = builtins.readFile ./config.nu;
    environmentVariables = {
      CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
      CARAPACE_MATCH = "1";
    };
  };
}
