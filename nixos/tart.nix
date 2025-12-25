# NixOS configuration for Tart (Apple Virtualization)
{
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # Enable flakes for nixos-rebuild
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader - GRUB with EFI (required by Apple Virtualization)
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Virtio modules for Apple Virtualization framework
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
    "virtio_balloon"
    "virtiofs"
  ];

  # Load virtio-gpu early for framebuffer console
  boot.initrd.kernelModules = [ "virtio_gpu" ];

  # Console configuration for Apple Virtualization
  # tty1 = framebuffer console (what you see in the Tart window)
  # hvc0 = hypervisor console (serial, for --serial flag)
  boot.kernelParams = [
    "console=tty1"
    "console=hvc0"
  ];

  # Disk configuration
  boot.growPartition = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # Networking
  networking.hostName = "nixos-tart";

  # Main user
  users.users.otahontas = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video" # for Sway/Wayland
    ];
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNqZN/gQy2WDb5T4f9dLpmNQ1YhJDfq3eB12lZDvX8J"
    ];
  };

  # Allow wheel group to sudo without password (convenient for VMs)
  security.sudo.wheelNeedsPassword = false;

  # SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraOptions = [
      "--unsupported-gpu" # Required for virtio-gpu
    ];
  };

  # greetd display manager - auto-login to Sway
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway";
        user = "otahontas";
      };
    };
  };

  # XDG portal for Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    noto-fonts
    noto-fonts-emoji
  ];

  # Dev tools for iterating on config
  environment.systemPackages = with pkgs; [
    neovim
    git
    htop
    curl
    wget
    ripgrep
    fd
    tree

    # Sway essentials
    foot # terminal
    wmenu # launcher (dmenu for wayland)
    swaylock
    swayidle
    grim # screenshots
    slurp # region selection
    wl-clipboard
    mako # notifications
  ];

  # Set neovim as default editor
  environment.variables.EDITOR = "nvim";

  # Environment for Sway in VM
  environment.sessionVariables = {
    WLR_RENDERER = "pixman"; # Software rendering for virtio-gpu
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  system.stateVersion = "24.11";
}
