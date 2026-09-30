{ pkgs, lib, ... }:
{
  home.activation.iinaFileAssociations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.duti}/bin/duti -s com.colliderli.iina .wav all
    ${pkgs.duti}/bin/duti -s com.colliderli.iina .mp3 all
  '';
}
