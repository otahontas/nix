if not type -q ykman
    echo "ykman not found. Install YubiKey Manager first." >&2
    return 1
end

function __yk_status_run_section
    set -l title $argv[1]

    echo ""
    echo "== $title =="

    if not $argv[2..-1]
        echo "  (not available)"
    end
end

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

functions -e __yk_status_run_section
