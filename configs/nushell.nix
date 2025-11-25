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

      let skim_base = "fd --hidden --follow --strip-cwd-prefix"
      $env.SKIM_DEFAULT_OPTIONS = "--height 50% --layout=reverse"
      $env.SKIM_DEFAULT_COMMAND = $skim_base
      $env.SKIM_ALT_C_COMMAND = $"($skim_base) --type directory"
      $env.SKIM_ALT_C_OPTS = "--preview 'eza -la --color=always {}' --select-1 --exit-0"
      $env.SKIM_CTRL_T_COMMAND = $"($skim_base) --type file"
      $env.SKIM_CTRL_T_OPTS = "--preview 'bat --style=numbers --color=always --line-range :500 {}' --select-1 --exit-0"
    '';

    extraConfig = builtins.readFile ./nushell/rose_pine_dawn.nu + builtins.readFile ./nushell/config.nu;
  };
}
