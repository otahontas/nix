{ pkgs, config, ... }:
let
  passwordStoreDir = "${config.xdg.dataHome}/password-store";
in
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = passwordStoreDir;
    };
  };

  programs.nushell.environmentVariables = {
    PASSWORD_STORE_DIR = passwordStoreDir;
  };
}
