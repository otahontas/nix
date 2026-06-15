{ pkgs, lib, ... }:
# Declarative Mac App Store apps via mas.
# Waiting for native nix-darwin module: https://github.com/nix-darwin/nix-darwin/pull/1668
# Once merged, migrate to programs.mas.apps in system config.
{
  home.activation.installMacAppStoreApps = lib.hm.dag.entryAfter [ "copyApps" ] ''
    ${pkgs.mas}/bin/mas install 363738376  # forScore
    ${pkgs.mas}/bin/mas install 409035833  # iReal Pro
    ${pkgs.mas}/bin/mas install 361285480  # Keynote
    ${pkgs.mas}/bin/mas install 634148309  # Logic Pro
    ${pkgs.mas}/bin/mas install 1263070803 # Lungo
    ${pkgs.mas}/bin/mas install 634159523  # MainStage
    ${pkgs.mas}/bin/mas install 1303222628 # Paprika Recipe Manager 3
    ${pkgs.mas}/bin/mas install 1276493162 # reMarkable
    ${pkgs.mas}/bin/mas install 803453959  # Slack
    ${pkgs.mas}/bin/mas install 747648890  # Telegram
    ${pkgs.mas}/bin/mas install 583995251  # uFocus
    ${pkgs.mas}/bin/mas install 1607635845 # Velja
    ${pkgs.mas}/bin/mas install 310633997  # WhatsApp
  '';
}
