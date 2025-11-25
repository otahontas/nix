{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    carapace
    commitlint
    fd
    git-crypt
    gitleaks
    gnugrep
    lefthook
    (llm.withPlugins {
      llm-cmd = true;
    })
    ripgrep
    uv
    wget
  ];
}
