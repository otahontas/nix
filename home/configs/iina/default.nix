{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.iina ];

  home.activation.iinaFileAssociations = lib.hm.dag.entryAfter [ "copyApps" ] ''
    ${pkgs.duti}/bin/duti -s com.colliderli.iina .wav all
    ${pkgs.duti}/bin/duti -s com.colliderli.iina .mp3 all
  '';
}
