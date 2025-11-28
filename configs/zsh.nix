{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = false;

    envExtra = ''
      # Override compinit before /etc/zshrc runs to prevent .zcompdump
      compinit() { :; }
      bashcompinit() { :; }
    '';

    initContent = ''
      # Disable history completely
      unset HISTFILE
      export HISTSIZE=0
      export SAVEHIST=0
    '';
  };
}
