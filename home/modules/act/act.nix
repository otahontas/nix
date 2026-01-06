{ pkgs, ... }:
{
  home.packages = with pkgs; [
    act
  ];
  xdg.configFile."act/actrc".source = ./actrc;
}
