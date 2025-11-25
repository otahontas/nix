{ ... }:
{
  home.file = {
    ".local/bin/gh-release-slack" = {
      source = ./local-scripts/gh-release-slack;
      executable = true;
    };
    ".local/bin/matlab" = {
      source = ./local-scripts/matlab;
      executable = true;
    };
    ".local/bin/mac-open" = {
      source = ./local-scripts/mac-open;
      executable = true;
    };
  };
}
