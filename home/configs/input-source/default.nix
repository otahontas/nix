{ lib, ... }:
{
  # TODO: this doesn't work, fix
  # Disable Control+Space shortcut for switching input sources
  # so it passes through to terminal/neovim (blink.cmp uses C-space for completion menu)
  home.activation.disableCspaceInputSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
      -dict-add 60 '<dict><key>enabled</key><false/></dict>'
  '';
}
