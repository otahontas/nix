{ pkgs, ... }:
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    };
  };

  programs.nushell.extraEnv = ''
    $env.PASSWORD_STORE_DIR = $"($env.HOME)/.local/share/password-store"
  '';
}
