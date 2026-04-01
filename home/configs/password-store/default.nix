{ config, pkgs, ... }:
let
  pass-passkey = pkgs.stdenvNoCC.mkDerivation {
    pname = "pass-extension-passkey";
    version = "1.0.1";
    src = ./passkey.bash;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/lib/password-store/extensions
      install -m755 $src $out/lib/password-store/extensions/passkey.bash
    '';
  };
in
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
      pass-passkey
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
    };
  };
}
