{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    carapace
    commitlint
    fd
    gitleaks
    lefthook
    ripgrep
    skim
    uv
    wget
  ];
}
