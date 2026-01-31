# Main NixOS configuration for otapi
{
  pkgs,
  username,
  sshKeys,
  ...
}:
{
  system.stateVersion = "24.11";

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ username ];
  };

  # Networking
  networking = {
    hostName = "otapi";
    useDHCP = true;

    firewall = {
      enable = true;

      # Only SSH open on LAN - needed for initial setup and recovery
      allowedTCPPorts = [ 22 ];

      # All other services only accessible via Tailscale
      # Tailscale interface is trusted (see tailscale config)
    };
  };

  # Timezone
  time.timeZone = "Europe/Helsinki";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # User account
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
    hashedPassword = "!"; # Disable password login entirely
  };

  # Disable root account
  users.users.root.hashedPassword = "!";

  # Require password for sudo (more secure with SSH key-only access)
  security.sudo = {
    wheelNeedsPassword = false; # Since password is disabled, use SSH agent forwarding
    execWheelOnly = true; # Only wheel group can use sudo
  };

  # SSH server - hardened
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      ChallengeResponseAuthentication = false;
      X11Forwarding = false;
      PermitEmptyPasswords = false;
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      AllowUsers = [ username ];
    };
  };

  # Fail2ban - protect against brute force (defense in depth)
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment.enable = true; # Increase ban time for repeat offenders
  };

  # Automatic security updates
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    allowReboot = false; # Don't auto-reboot, but apply updates
    flake = "git+file:///etc/nixos#otapi"; # Will need to be updated after setup
  };

  # Kernel hardening
  boot.kernel.sysctl = {
    # Disable IP forwarding (not a router)
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;

    # Ignore ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;

    # Don't send ICMP redirects
    "net.ipv4.conf.all.send_redirects" = 0;

    # Ignore source-routed packets
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;

    # Log suspicious packets
    "net.ipv4.conf.all.log_martians" = 1;

    # Protect against SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;

    # Ignore broadcast pings
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    tmux
  ];

  # Garbage collection to save space on SD card
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
