{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    carapace
    commitlint
    fd
    gitleaks
    ripgrep
    skim
    uv
    wget
  ];
}
