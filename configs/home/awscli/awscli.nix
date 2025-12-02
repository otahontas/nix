{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    awscli2
  ];
  home.file.".local/bin/generate-aws-config".source = ./generate-aws-config.nu;
  home.file.".local/bin/generate-aws-config".executable = true;
  launchd.agents.generate-aws-config = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.nushell}/bin/nu"
        "${config.home.homeDirectory}/.local/bin/generate-aws-config"
        "${pkgs.pass}/bin/pass"
      ];
      EnvironmentVariables = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.local/share/password-store";
        HOME = config.home.homeDirectory;
      };
      RunAtLoad = true;
      StandardOutPath = "/tmp/generate-aws-config.out.log";
      StandardErrorPath = "/tmp/generate-aws-config.err.log";
    };
  };
}
