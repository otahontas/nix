{ config, ... }:
{
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
      mkdir ($nu.cache-dir)
      carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
    '';

    extraConfig = builtins.readFile ./nushell/config.nu;
  };
}
