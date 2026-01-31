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

    # Extra paranoia: explicitly allow services only on tailscale0
    extraCommands = ''
      # Allow Home Assistant only via Tailscale
      iptables -A INPUT -i tailscale0 -p tcp --dport 8123 -j ACCEPT
      iptables -A INPUT -p tcp --dport 8123 -j DROP

      # Allow Soft-serve only via Tailscale
      iptables -A INPUT -i tailscale0 -p tcp --dport 23231 -j ACCEPT
      iptables -A INPUT -p tcp --dport 23231 -j DROP
      iptables -A INPUT -i tailscale0 -p tcp --dport 23232 -j ACCEPT
      iptables -A INPUT -p tcp --dport 23232 -j DROP
    '';

    extraStopCommands = ''
      iptables -D INPUT -i tailscale0 -p tcp --dport 8123 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 8123 -j DROP || true
      iptables -D INPUT -i tailscale0 -p tcp --dport 23231 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 23231 -j DROP || true
      iptables -D INPUT -i tailscale0 -p tcp --dport 23232 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 23232 -j DROP || true
    '';
  };

  # CLI tool
  environment.systemPackages = [ pkgs.tailscale ];
}
