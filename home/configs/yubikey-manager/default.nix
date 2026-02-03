{ pkgs, ... }:
{
  home.packages = [ pkgs.yubikey-manager ];

  programs.fish.functions = {
    "yk-status" = {
      description = "Show YubiKey status via ykman";
      body = builtins.readFile ./yk-status.fish;
    };
  };
}
