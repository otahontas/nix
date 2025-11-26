{ ... }:
{
  home.file = {
    ".local/bin/matlab" = {
      source = ./local-scripts/matlab;
      executable = true;
    };
  };
}
