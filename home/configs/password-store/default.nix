{ config, pkgs, ... }:
let
  appId = "com.github.browserpass.native";
in
{
  home.packages = [
    pkgs.zbar # needed for pass-otp QR code scanning
    pkgs.browserpass
  ];

  # Browserpass native host manifest for Firefox.app (Homebrew) on macOS
  home.file."Library/Application Support/Mozilla/NativeMessagingHosts/${appId}.json".source =
    "${pkgs.browserpass}/lib/mozilla/native-messaging-hosts/${appId}.json";

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-genphrase
      exts.pass-update
      pkgs.passExtensions.pass-extension-passkey
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
    };
  };
}
