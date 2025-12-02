{ pkgs, ... }:
{
  home.packages = with pkgs; [
    carapace
  ];
  programs.nushell.extraEnv = ''
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
    $env.CARAPACE_MATCH = '1'
    mkdir ($nu.cache-dir)
    carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
  '';
}
