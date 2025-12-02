{ pkgs, ... }:
{
  programs.mise = {
    enable = true;
    enableNushellIntegration = true;
    globalConfig = {
      settings = {
        experimental = true;
      };
      tools = {
        rust = "latest";
        node = "latest";
        python = "latest";
        go = "latest";
      };
    };
  };
}
