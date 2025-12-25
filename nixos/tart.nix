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

  # Admin user with password login
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "admin";
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

  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
  ];

  system.stateVersion = "24.11";
}
