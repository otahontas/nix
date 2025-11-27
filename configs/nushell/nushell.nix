{ pkgs, config, lib, ... }:
let
  # Auto-discover tool integrations
  configsDir = ../.;

  # Get all subdirectories in configs/
  toolDirs = builtins.readDir configsDir;

  # For each tool dir, check if tool.nu exists and read it
  # Skip nushell directory to avoid duplicates
  collectNuFiles = lib.attrsets.mapAttrsToList (name: type:
    let
      nuFile = configsDir + "/${name}/${name}.nu";
    in
      if type == "directory" && name != "nushell" && builtins.pathExists nuFile
      then builtins.readFile nuFile
      else ""
  ) toolDirs;

  # Combine all tool integrations
  allIntegrations = lib.concatStrings collectNuFiles;

  # Read core nushell config
  coreConfig = builtins.readFile ./nushell.nu;
in
{
  home.packages = with pkgs; [
    carapace
    (llm.withPlugins {
      llm-cmd = true;
    })
  ];

  catppuccin.nushell.enable = true;

  programs.nushell = {
    enable = true;
    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep)
        | prepend "${config.home.homeDirectory}/.local/bin"
        | prepend "/etc/profiles/per-user/${config.home.username}/bin"
        | prepend "/run/current-system/sw/bin"
        | prepend "/nix/var/nix/profiles/default/bin"
        | uniq
      )

      $env.VISUAL = "nvim"
      $env.EDITOR = "nvim"

      # Testcontainers support for Colima
      $env.DOCKER_HOST = $"unix://($env.HOME)/.colima/default/docker.sock"
      $env.TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock"
      $env.NODE_OPTIONS = "--dns-result-order=ipv4first"

      $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
      $env.CARAPACE_MATCH = '1'
      mkdir ($nu.cache-dir)
      carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
    '';

    # Load core config + auto-discovered tool integrations
    extraConfig = coreConfig + "\n" + allIntegrations;
  };
}
