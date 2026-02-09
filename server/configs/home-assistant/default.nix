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
      # Minimal config required to start
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Helsinki";
      };

      # Enable frontend for initial setup/restore
      frontend = { };

      # Restore default_config from your backup
      default_config = { };

      # Keep Google Translate TTS
      tts = [
        {
          platform = "google_translate";
        }
      ];

      # Include files to match your backup structure
      # These files will be restored from backup to /var/lib/hass
      group = "!include groups.yaml";
      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";

      # Allow HTTP for initial access
      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
    };
  };

  # Ensure config files exist for includes so HA doesn't fail on first boot
  # Your restore will overwrite these empty files
  systemd.tmpfiles.rules = [
    "f /var/lib/hass/automations.yaml 0644 hass hass - []"
    "f /var/lib/hass/scripts.yaml 0644 hass hass - []"
    "f /var/lib/hass/scenes.yaml 0644 hass hass - []"
    "f /var/lib/hass/groups.yaml 0644 hass hass - []"
  ];
}
