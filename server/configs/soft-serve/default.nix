# Soft-serve git server
{ pkgs, sshKeys, ... }:
{
  users.users.soft-serve = {
    isSystemUser = true;
    group = "soft-serve";
    home = "/var/lib/soft-serve";
    createHome = true;
  };

  users.groups.soft-serve = { };

  systemd.services.soft-serve = {
    description = "Soft Serve git server";
    after = [
      "network.target"
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      SOFT_SERVE_DATA_PATH = "/var/lib/soft-serve";
      # Bind to all interfaces - firewall restricts to Tailscale only
      SOFT_SERVE_SSH_LISTEN_ADDR = ":23231";
      SOFT_SERVE_HTTP_LISTEN_ADDR = ":23232";
      SOFT_SERVE_INITIAL_ADMIN_KEYS = builtins.concatStringsSep "\n" sshKeys;
    };

    serviceConfig = {
      Type = "simple";
      User = "soft-serve";
      Group = "soft-serve";
      ExecStart = "${pkgs.soft-serve}/bin/soft-serve";
      Restart = "always";
      RestartSec = 5;
      StateDirectory = "soft-serve";

      # Security hardening
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      ReadWritePaths = [ "/var/lib/soft-serve" ];
    };
  };
}
