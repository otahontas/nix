{ pkgs, config, ... }:
{
  # Install script to generate .npmrc from pass
  home.file.".local/bin/generate-npmrc".source = ./generate-npmrc.nu;
  home.file.".local/bin/generate-npmrc".executable = true;

  # Generate .npmrc from pass via launchd service
  launchd.agents.generate-npmrc = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.nushell}/bin/nu"
        "${config.home.homeDirectory}/.local/bin/generate-npmrc"
        "${pkgs.pass}/bin/pass"
      ];
      EnvironmentVariables = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.local/share/password-store";
        HOME = config.home.homeDirectory;
      };
      RunAtLoad = true;
      StandardOutPath = "/tmp/generate-npmrc.out.log";
      StandardErrorPath = "/tmp/generate-npmrc.err.log";
    };
  };
}
