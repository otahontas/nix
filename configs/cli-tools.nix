{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    commitlint
    fd
    gitleaks
    nodejs_22
    ripgrep
    skim
    uv
    wget
  ];
}
