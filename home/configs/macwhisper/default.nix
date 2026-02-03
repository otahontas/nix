{ pkgs, lib, ... }:
let
  macwhisper = pkgs.callPackage ../../packages/macwhisper.nix { };
in
{
  home.packages = [ macwhisper ];

  home.activation.clearMacwhisperQuarantine = lib.hm.dag.entryAfter [ "copyApps" ] ''
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/MacWhisper.app" 2>/dev/null || true
  '';
}
