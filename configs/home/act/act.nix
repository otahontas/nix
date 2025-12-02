{ pkgs, ... }:
{
  home.packages = with pkgs; [
    act
  ];
  home.file.".config/act/actrc".source = ./actrc;
}
