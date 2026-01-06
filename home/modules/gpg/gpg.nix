{ pkgs, config, ... }:
let
  sshAgentSocket = "${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh";

  pinentry-touchid = pkgs.stdenv.mkDerivation rec {
    pname = "pinentry-touchid";
    version = "0.0.4";
    src = pkgs.fetchzip {
      url = "https://github.com/lujstn/pinentry-touchid/releases/download/v${version}/pinentry-touchid_${version}_darwin_arm64.tar.gz";
      sha256 = "sha256-9IUkxzdE03odiGHIISJM/OSsrf05DO65dZAdV9oXJNA=";
      stripRoot = false;
    };
    installPhase = ''
      mkdir -p $out/bin
      cp pinentry-touchid $out/bin/
      chmod +x $out/bin/pinentry-touchid
    '';
    meta.mainProgram = "pinentry-touchid";
  };

in
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
    enableSshSupport = true;
    sshKeys = [ "5A8603AB609BD3D5EDED2B2E53D22ABA6B268956" ];
    pinentry.package = pinentry-touchid;
    defaultCacheTtl = 300;
    maxCacheTtl = 900;
  };

  programs.ssh.matchBlocks."*".identityAgent = sshAgentSocket;
  programs.nushell.environmentVariables.SSH_AUTH_SOCK = sshAgentSocket;
}
