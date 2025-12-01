{ pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      use-agent = true;
      auto-key-retrieve = true;
      no-emit-version = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.package = pkgs.pinentry_mac;
    defaultCacheTtl = 7200; # 2 hours
    maxCacheTtl = 7200; # 2 hours
  };
}
