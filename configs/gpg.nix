{ pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      auto-key-retrieve = true;
      no-emit-version = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.package = pkgs.pinentry_mac;
    defaultCacheTtl = 604800;
    maxCacheTtl = 604800;
  };
}
