_: {
  system.activationScripts.keyboard.text = ''
    echo "Installing keyboard layout system-wide..."
    mkdir -p "/Library/Keyboard Layouts"
    cp ${./us-international-nodeadkeys.keylayout} "/Library/Keyboard Layouts/U.S. International wo dead keys.keylayout"
    chmod 644 "/Library/Keyboard Layouts/U.S. International wo dead keys.keylayout"
  '';
}
