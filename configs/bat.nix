{ pkgs, ... }:
let
  rose-pine-bat = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "tm-theme";
    rev = "c4235f9a65fd180ac0f5e4396e3a86e21a0884ec";
    hash = "sha256-jji8WOKDkzAq8K+uSZAziMULI8Kh7e96cBRimGvIYKY=";
  };
in
{
  programs.bat = {
    enable = true;
    config = {
      theme = "rose-pine-dawn";
    };
    themes = {
      rose-pine-dawn = {
        src = rose-pine-bat;
        file = "dist/themes/rose-pine-dawn.tmTheme";
      };
    };
  };
}
