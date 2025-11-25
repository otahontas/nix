{ pkgs, lib, ... }:
let
  rose-pine-starship = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "starship";
    rev = "0edc3c781f219565453bbb8e8e7af56ebc2a0d8a";
    hash = "sha256-r7q7nyGPXCMwVzVqrOXcskAnPFT07jDY91sB3C8b1Ow=";
  };
in
{
  programs.starship = {
    enable = true;
    settings = lib.importTOML "${rose-pine-starship}/rose-pine-dawn.toml";
  };
}
