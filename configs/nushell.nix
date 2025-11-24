{ config, ... }:
{
  programs.nushell = {
    enable = true;
    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep)
        | prepend "/etc/profiles/per-user/${config.home.username}/bin"
        | prepend "/run/current-system/sw/bin"
        | prepend "/nix/var/nix/profiles/default/bin"
        | uniq
      )
    '';

    extraConfig = builtins.readFile ./nushell/rose_pine_dawn.nu + ''

      # Generate LS_COLORS with vivid using rose-pine-dawn theme
      $env.LS_COLORS = (vivid generate rose-pine-dawn)

      # Additional Nushell configuration
      $env.config.show_banner = false
    '';
  };
}
