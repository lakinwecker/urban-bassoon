#!/usr/bin/env bash
# Installs the asus-tuf NixOS config onto this machine.
# WIPES both NVMe drives. Run from inside the cloned flake repo on the live ISO.
#
# Two-phase: disko (format+mount) first, then nixos-install. Verifies
# /mnt is actually a real filesystem before copying, so we don't
# silently land on the live ISO's tmpfs and run out of space at 12 GiB.
set -euo pipefail

# Disk identities are hard-coded in disko-config-asus-tuf.nix, so we
# don't pass --disk flags here. These are just for sanity checks.
MAIN_ID="nvme-WD_PC_SN5000S_SDEQNSJ-1T00-1002_25184R800947"
HOME_ID="nvme-KINGSTON_SNV3S1000G_50026B76873F13D6"
MAIN_DISK="/dev/disk/by-id/${MAIN_ID}"
HOME_DISK="/dev/disk/by-id/${HOME_ID}"

for d in "$MAIN_DISK" "$HOME_DISK"; do
  if [ ! -e "$d" ]; then
    echo "ERROR: $d not found. Update the *_ID vars in this script AND in disko-config-asus-tuf.nix." >&2
    exit 1
  fi
done

echo "About to WIPE and install NixOS asus-tuf onto:"
echo "  main (ESP + / + /nix): $MAIN_DISK -> $(readlink -f "$MAIN_DISK")"
echo "  home (/home):          $HOME_DISK -> $(readlink -f "$HOME_DISK")"
echo
read -r -p "Type 'WIPE' to continue: " confirm
[ "$confirm" = "WIPE" ] || { echo "Aborted."; exit 1; }

if [ ! -s /tmp/disk-password ]; then
  echo
  echo "Enter LUKS passphrase (used for BOTH disks):"
  read -r -s pass1
  echo "Confirm passphrase:"
  read -r -s pass2
  [ "$pass1" = "$pass2" ] || { echo "Passphrases do not match."; exit 1; }
  printf '%s' "$pass1" | sudo tee /tmp/disk-password >/dev/null
  sudo chmod 600 /tmp/disk-password
  unset pass1 pass2
fi

NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')

echo
echo "==> Phase 1: disko (destroy, format, mount)"
sudo nix "${NIX_FLAGS[@]}" run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --root-mountpoint /mnt \
  --flake .#asus-tuf

echo
echo "==> Verifying /mnt is a real filesystem, not tmpfs"
MNT_FSTYPE="$(findmnt -n -o FSTYPE /mnt || true)"
if [ "$MNT_FSTYPE" != "btrfs" ]; then
  echo "ERROR: /mnt is not btrfs (got '$MNT_FSTYPE'). Disko mount failed silently. Aborting." >&2
  echo
  echo "Current mounts:"
  mount | grep -E 'mnt|crypt' || true
  exit 1
fi

MNT_HOME_FSTYPE="$(findmnt -n -o FSTYPE /mnt/home || true)"
if [ "$MNT_HOME_FSTYPE" != "btrfs" ]; then
  echo "ERROR: /mnt/home is not btrfs (got '$MNT_HOME_FSTYPE'). home disk was not mounted. Aborting." >&2
  exit 1
fi

MNT_BOOT_FSTYPE="$(findmnt -n -o FSTYPE /mnt/boot || true)"
if [ "$MNT_BOOT_FSTYPE" != "vfat" ]; then
  echo "ERROR: /mnt/boot is not vfat (got '$MNT_BOOT_FSTYPE'). ESP was not mounted. Aborting." >&2
  exit 1
fi

echo "  / (btrfs):    $(df -h /mnt      | tail -1 | awk '{print $2" total, "$4" free"}')"
echo "  /home (btrfs):$(df -h /mnt/home | tail -1 | awk '{print $2" total, "$4" free"}')"
echo "  /boot (vfat): $(df -h /mnt/boot | tail -1 | awk '{print $2" total, "$4" free"}')"

echo
echo "==> Phase 2: nixos-install"
sudo nixos-install \
  --root /mnt \
  --flake .#asus-tuf \
  --no-root-passwd

echo
echo "Install complete. Unmounting and closing LUKS."
sudo umount -R /mnt || true
sudo cryptsetup close cryptroot 2>/dev/null || true
sudo cryptsetup close crypthome 2>/dev/null || true

echo
echo "Done. You can now reboot."
