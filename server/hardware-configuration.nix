# Hardware configuration for Raspberry Pi 4 (2GB)
{ lib, ... }:
{
  # Boot configuration for SD card
  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Required for Pi 4
    kernelParams = [ "console=ttyS1,115200n8" ];
  };

  # Filesystem - SD card
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # Swap file for 2GB RAM - helps prevent OOM
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # 2GB swap
    }
  ];

  # Hardware settings
  hardware = {
    enableRedistributableFirmware = true;
  };

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
