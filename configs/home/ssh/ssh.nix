{ ... }:
{
  # TODO: check this through and especially remove 1passowrd setup
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.colima/ssh_config"
      "~/.ssh/keys.conf"
      "~/.ssh/1Password/config"
    ];
    matchBlocks = {
      "*" = {
        identityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
      };
    };
  };
}
