{ pkgs, config, ... }:
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    };
  };

  programs.nushell.environmentVariables = {
    PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.local/share/password-store";
  };
}
