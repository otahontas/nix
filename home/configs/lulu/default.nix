{ pkgs, lib, ... }:
let
  lulu = pkgs.callPackage ../../packages/lulu.nix { };
in
{
  home.packages = [ lulu ];

  home.activation.clearLuluQuarantine = lib.hm.dag.entryAfter [ "copyApps" ] ''
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/LuLu.app" 2>/dev/null || true
  '';
}
