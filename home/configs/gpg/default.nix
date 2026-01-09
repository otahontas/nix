{ config, pkgs, ... }:
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ "5A8603AB609BD3D5EDED2B2E53D22ABA6B268956" ];
    pinentry.package = pkgs.pinentry_mac;
    defaultCacheTtl = 300;
    maxCacheTtl = 900;
  };

  programs.gpg = {
    enable = true;
    settings = {
      use-agent = true;
      auto-key-retrieve = true;
      no-emit-version = true;
    };
  };

  programs.ssh.matchBlocks."*".identityAgent = "${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh";
}
