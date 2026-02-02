{ pkgs, lib, ... }:
let
  pearcleaner = pkgs.callPackage ../../packages/pearcleaner.nix { };
in
{
  home.packages = [ pearcleaner ];

  # Clear quarantine attributes after copyApps runs
  home.activation.clearPearcleanerQuarantine = lib.hm.dag.entryAfter [ "copyApps" ] ''
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/Pearcleaner.app" 2>/dev/null || true
  '';
}
