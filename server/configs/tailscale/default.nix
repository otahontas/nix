# Tailscale VPN client
{ pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Tailscale interface is trusted - services bound here are secure
  # All sensitive services (Home Assistant, Soft-serve) only accessible via Tailscale
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ]; # Tailscale WireGuard port
  };

  # CLI tool
  environment.systemPackages = [ pkgs.tailscale ];
}
