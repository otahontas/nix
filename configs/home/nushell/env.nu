$env.PATH = (
  $env.PATH | split row (char esep)
  | prepend $"$env.XDG_BIN_HOME"
  | prepend $"/etc/profiles/per-user/($env.USER)/bin"
  | prepend "/run/current-system/sw/bin"
  | prepend "/nix/var/nix/profiles/default/bin"
  | uniq
)
