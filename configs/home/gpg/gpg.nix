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
    pinentry.package = pkgs.pinentry_mac; # TODO: pinentry touch id
    defaultCacheTtl = 7200;
    maxCacheTtl = 7200;
    # TODO: gpg subkeys for ssh
  };
}
