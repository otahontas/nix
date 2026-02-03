{ pkgs, lib, ... }:
let
  blockblock = pkgs.callPackage ../../packages/blockblock.nix { };
in
{
  home.packages = [ blockblock ];

  home.activation.clearBlockblockQuarantine = lib.hm.dag.entryAfter [ "copyApps" ] ''
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/BlockBlock.app" 2>/dev/null || true
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/BlockBlock Helper.app" 2>/dev/null || true
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/BlockBlock Installer.app" 2>/dev/null || true
  '';
}
