{ pkgs, lib, ... }:
# Declarative Mac App Store apps via mas.
# Waiting for native nix-darwin module: https://github.com/nix-darwin/nix-darwin/pull/1668
# Once merged, migrate to programs.mas.apps in system config.
{
  home.packages = [ pkgs.mas ];

  home.activation.installMacAppStoreApps = lib.hm.dag.entryAfter [ "copyApps" ] ''
    ${pkgs.mas}/bin/mas install 634148309  # Logic Pro
    ${pkgs.mas}/bin/mas install 1263070803 # Lungo
    ${pkgs.mas}/bin/mas install 634159523  # MainStage
    ${pkgs.mas}/bin/mas install 1607635845 # Velja
    ${pkgs.mas}/bin/mas install 747648890  # Telegram
    ${pkgs.mas}/bin/mas install 803453959  # Slack for Desktop
    ${pkgs.mas}/bin/mas install 310633997  # WhatsApp Messenger
  '';
}
