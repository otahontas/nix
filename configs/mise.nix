{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableNushellIntegration = true;
    globalConfig = {
      settings = {
        experimental = true;
      };
    };
  };
}
