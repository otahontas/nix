{ ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = false;

    initExtra = ''
      # Disable history completely
      unset HISTFILE
      export HISTSIZE=0
      export HISTFILESIZE=0
    '';
  };
}
