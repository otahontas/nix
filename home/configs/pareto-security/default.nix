{ pkgs, lib, ... }:
let
  paretoSecurity = pkgs.callPackage ../../packages/pareto-security.nix { };
in
{
  home.packages = [ paretoSecurity ];

  home.activation.clearParetoSecurityQuarantine = lib.hm.dag.entryAfter [ "copyApps" ] ''
    $DRY_RUN_CMD /usr/bin/xattr -cr "$HOME/Applications/Home Manager Apps/Pareto Security.app" 2>/dev/null || true
  '';
}
