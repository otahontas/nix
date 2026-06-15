{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.zbar # needed for pass-otp QR code scanning
  ];

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-genphrase
      exts.pass-update
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
    };
  };
}
