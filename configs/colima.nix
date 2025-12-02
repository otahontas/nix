{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    colima # Container runtime using Lima
    docker-client # Docker CLI for interacting with Colima
    docker-credential-helpers # Includes docker-credential-pass
  ];

  # Configure Docker to use pass for credential storage
  home.file.".docker/config.json".text = builtins.toJSON {
    credsStore = "pass";
    currentContext = "colima";
  };

  # Auto-start Colima on login
  launchd.agents.colima = {
    enable = true;
    config = {
      ProgramArguments = [
        "${lib.getExe pkgs.colima}"
        "start"
        "--foreground"
        # Customize these as needed:
        # "--cpu" "4"
        # "--memory" "4"
        # "--disk" "100"
      ];
      # Set PATH so Colima can find docker and other dependencies
      EnvironmentVariables = {
        PATH = "/etc/profiles/per-user/otahontas/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/colima.out.log";
      StandardErrorPath = "/tmp/colima.err.log";
    };
  };

}
