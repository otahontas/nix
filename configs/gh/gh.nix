{ ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      editor = "nvim";
      git_protocol = "ssh";
      pager = "bat";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        web = "repo view --web";
      };
    };
  };
}
