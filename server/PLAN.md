# otapi - Raspberry Pi home server

NixOS-based home server running on Raspberry Pi.

## Hardware

- Raspberry Pi 4 Model B
- 2GB RAM (limited - keep services lightweight)
- 64GB microSD card
- Official case and USB-C power supply

## Services (phase 1)

| Service        | Purpose            | Port                      |
| -------------- | ------------------ | ------------------------- |
| Home Assistant | Smart home control | 8123                      |
| Tailscale      | VPN mesh network   | 41641/udp                 |
| Soft-serve     | Private git server | 23231 (SSH), 23232 (HTTP) |

## Future services (not in phase 1)

- Time Machine backups via Samba
- Headscale (self-hosted Tailscale control server)

## Repository structure

```
~/.nix/
├── home/       # home-manager (macOS CLI tools)
├── system/     # nix-darwin (macOS system config)
└── server/     # nixos (raspberry pi)
    ├── flake.nix
    ├── flake.lock
    ├── configuration.nix
    ├── hardware-configuration.nix
    ├── justfile
    └── configs/
        ├── home-assistant/
        ├── tailscale/
        └── soft-serve/
```

## Initial setup guide

### 1. Backup current HAOS

1. Open Home Assistant web UI
2. Go to Settings → System → Backups
3. Create a full backup
4. Download the .tar file to your Mac

### 2. Download NixOS image

```bash
# Download the latest NixOS aarch64 SD image
curl -L -o ~/Downloads/nixos-sd.img.zst \
  "https://hydra.nixos.org/job/nixos/release-24.11/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image"

# Decompress it
zstd -d ~/Downloads/nixos-sd.img.zst
```

### 3. Flash to SD card

1. Power off Pi, remove SD card, insert into Mac
2. Find the disk:
   ```bash
   diskutil list
   ```
3. Flash (replace `diskN` with your SD card, e.g., `disk4`):
   ```bash
   diskutil unmountDisk /dev/diskN
   sudo dd if=~/Downloads/nixos-sd.img of=/dev/rdiskN bs=4m status=progress
   diskutil eject /dev/diskN
   ```

### 4. First boot and initial access

1. Insert SD card into Pi
2. Connect ethernet cable to router
3. Power on and wait ~2 minutes
4. Find Pi's IP address:
   - Check router admin page (DHCP leases), or
   - Run `arp -a | grep -i "dc:a6:32\|e4:5f:01"` (Pi MAC prefixes)
5. SSH in with default NixOS credentials:
   ```bash
   ssh nixos@<pi-ip-address>
   # Default password: nixos
   ```

### 5. Prepare for deployment

On the Pi (as nixos user):

```bash
# Add your SSH key for passwordless access
mkdir -p ~/.ssh
echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOyMapMZxX+mQ6hVk/uXhpkvRc4lGg5eVltxia8HP7NDIA0Xgn+6DVIVKiS6khcFF2p+3zCiKnwTpr0nloTfZmw= cardno:36_048_366" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Verify you can SSH with your key (from Mac in another terminal)
# ssh nixos@<pi-ip-address>
# Should not ask for password
```

### 6. Deploy configuration

From your Mac (in `~/.nix/server/`):

```bash
# First deployment (Pi needs to be accessible)
nixos-rebuild switch --flake .#otapi --target-host nixos@<pi-ip-address> --use-remote-sudo

# After first deploy, use:
just deploy
# or
just deploy-rebuild
```

### 7. Post-deployment setup

#### Tailscale

```bash
# SSH into Pi
just ssh

# Authenticate with Tailscale
sudo tailscale up

# Follow the URL to log in and authorize the device
```

#### Soft-serve

Access via SSH from your Mac:

```bash
# Browse repos (TUI)
ssh -p 23231 otapi

# Create a new repo
ssh -p 23231 otapi repo create my-repo

# Clone
git clone ssh://otapi:23231/my-repo
```

#### Home Assistant

1. Open http://otapi:8123 in browser
2. Complete initial setup
3. Restore backup: Settings → System → Backups → Upload backup → Restore

### 8. Add SSH config (optional)

Add to your Mac's `~/.ssh/config`:

```
Host otapi
    HostName otapi  # or Tailscale IP
    User otahontas
    Port 22

Host otapi-git
    HostName otapi
    User git
    Port 23231
```

## Ongoing deployment

```bash
cd ~/.nix/server

# Check configuration
just check

# Build locally first
just build

# Deploy to Pi
just deploy
```

## Useful commands

```bash
# SSH into Pi
just ssh

# Check service status
ssh otapi "systemctl status home-assistant"
ssh otapi "systemctl status soft-serve"
ssh otapi "systemctl status tailscaled"

# View logs
ssh otapi "journalctl -u home-assistant -f"

# Check memory usage
ssh otapi "htop"
```

## Security

### What's protected

| Layer    | Protection                                                   |
| -------- | ------------------------------------------------------------ |
| SSH      | Key-only (Yubikey), no root, no passwords, fail2ban          |
| Firewall | Only SSH on LAN, all services Tailscale-only                 |
| Services | Systemd hardening, unprivileged users                        |
| Kernel   | IP forwarding disabled, SYN flood protection, ICMP hardening |
| Accounts | Passwords disabled, sudo restricted to wheel                 |

### Access pattern

```
Internet ───X───> otapi (nothing exposed)
LAN ──[SSH]──> otapi (Yubikey required)
Tailscale ──> Home Assistant, Soft-serve, SSH
```

### Router configuration (DNA)

**Critical: Do NOT port forward anything to the Pi.**

| Setting           | Value            | Why                                 |
| ----------------- | ---------------- | ----------------------------------- |
| Port forwarding   | **None to Pi**   | All access via Tailscale            |
| UPnP              | **Disable**      | Prevents devices from opening ports |
| Remote management | **Disable**      | Router admin only from LAN          |
| Firewall          | **Enabled**      | Default should be fine              |
| WiFi              | WPA3 or WPA2-AES | No WEP/TKIP                         |

## Notes

- **RAM:** 2GB is tight. Added 2GB swap file to help prevent OOM.
- **SD card:** Enable weekly garbage collection to save space.
- **Home Assistant:** May need to add specific `extraComponents` after migration based on your integrations.
- **Soft-serve:** Your SSH keys are pre-configured as admin keys.
