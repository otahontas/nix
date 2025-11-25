{ config, ... }:
{
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

      $env.BAT_THEME = "rose-pine-dawn"
      $env.VISUAL = "nvim"
      $env.EDITOR = "nvim"

      $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
      mkdir ($nu.cache-dir)
      carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
    '';

    extraConfig = builtins.readFile ./nushell/rose_pine_dawn.nu + builtins.readFile ./nushell/config.nu;
  };
}
