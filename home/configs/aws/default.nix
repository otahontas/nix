{
  pkgs,
  lib,
  config,
  ...
}:
let
  awsDir = "$HOME/.aws";
  configFile = "${awsDir}/config";

  # wrap aws-creds.sh script as a proper binary with all dependencies
  passWithExtensions = config.programs.password-store.package;
  aws-creds = pkgs.writeShellScriptBin "aws-creds" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.awscli2
        pkgs.jq
        pkgs.gnupg
        passWithExtensions
      ]
    }:$PATH"
    exec ${./.}/aws-creds.sh "$@"
  '';
in
{
  home.packages = [
    pkgs.awscli2
    aws-creds
  ];

  programs.fish.interactiveShellInit = builtins.readFile ./config.fish;

  # fetch aws config from pass on every activation. using chflags uchg to make
  # files immutable (macOS equivalent of chattr +i)
  home.activation.awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $VERBOSE_ECHO "Fetching AWS config from pass"
    mkdir -p ${awsDir}
    if [ -f ${configFile} ]; then /usr/bin/chflags nouchg ${configFile}; fi
    ${passWithExtensions}/bin/pass aws/config > ${configFile}
    /usr/bin/chflags uchg ${configFile}
  '';
}
