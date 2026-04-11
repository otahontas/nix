{ pkgs, ... }:
let
  yk-status = pkgs.writeShellScriptBin "yk-status" ''
    if ! command -v ykman &>/dev/null; then
      echo "ykman not found. Install YubiKey Manager first." >&2
      exit 1
    fi

    __yk_status_run_section() {
      local title="$1"
      shift
      echo ""
      echo "== $title =="
      if ! "$@"; then
        echo "  (not available)"
      fi
    }

    __yk_status_run_section "YubiKey info" ykman info
    __yk_status_run_section "USB interfaces" ykman config usb
    __yk_status_run_section "NFC interfaces" ykman config nfc

    __yk_status_run_section OTP ykman otp info
    __yk_status_run_section FIDO2 ykman fido info
    __yk_status_run_section "FIDO2 passkeys (resident credentials)" ykman fido credentials list
    __yk_status_run_section OpenPGP ykman openpgp info
    __yk_status_run_section "PIV (certificates/keys)" ykman piv info
    __yk_status_run_section OATH ykman oath info
    __yk_status_run_section "OATH accounts (OTP/TOTP)" ykman oath accounts list
  '';
in
{
  home = {
    packages = [
      pkgs.yubikey-manager
      yk-status
    ];
  };
}
