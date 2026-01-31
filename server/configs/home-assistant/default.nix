# Home Assistant
_: {
  services.home-assistant = {
    enable = true;

    # Extra components to load - add more as needed based on your integrations
    extraComponents = [
      # Common integrations
      "default_config"
      "met" # Weather
      "esphome"
      "mobile_app"

      # Add your specific integrations here after migration
      # Check your HAOS setup for which ones you need
    ];

    # Extra packages for Python integrations
    extraPackages =
      ps: with ps; [
        # Add Python packages needed by your integrations
      ];

    # Basic config - most settings come from UI / restored backup
    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Helsinki";
      };

      # Enable frontend
      frontend = { };

      # HTTP configuration - secured
      http = {
        # Only listen on localhost and Tailscale
        # Tailscale IP will be assigned dynamically, so we bind to all but firewall restricts
        server_host = "0.0.0.0";
        server_port = 8123;

        # Security settings
        use_x_forwarded_for = false;
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      # Enable other common features
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";
    };
  };

  # Ensure config files exist for includes
  systemd.tmpfiles.rules = [
    "f /var/lib/hass/automations.yaml 0644 hass hass - []"
    "f /var/lib/hass/scripts.yaml 0644 hass hass - []"
    "f /var/lib/hass/scenes.yaml 0644 hass hass - []"
  ];
}
