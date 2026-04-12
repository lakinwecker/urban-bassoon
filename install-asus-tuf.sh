#!/usr/bin/env bash
# Installs the asus-tuf NixOS config onto this machine.
# WIPES both NVMe drives. Run from inside the cloned flake repo on the live ISO.
set -euo pipefail

MAIN_ID="nvme-WD_PC_SN5000S_SDEQNSJ-1T00-1002_25184R800947"
HOME_ID="nvme-KINGSTON_SNV3S1000G_50026B76873F13D6"

MAIN_DISK="/dev/disk/by-id/${MAIN_ID}"
HOME_DISK="/dev/disk/by-id/${HOME_ID}"

if [ ! -e "$MAIN_DISK" ]; then
  echo "ERROR: $MAIN_DISK not found. Update MAIN_ID in this script." >&2
  exit 1
fi
if [ ! -e "$HOME_DISK" ]; then
  echo "ERROR: $HOME_DISK not found. Update HOME_ID in this script." >&2
  exit 1
fi

echo "About to WIPE and install NixOS asus-tuf onto:"
echo "  main (ESP + root/nix/home pool): $MAIN_DISK -> $(readlink -f "$MAIN_DISK")"
echo "  home (absorbed into pool):       $HOME_DISK -> $(readlink -f "$HOME_DISK")"
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

if command -v disko-install >/dev/null; then
  DISKO=(sudo disko-install)
else
  DISKO=(sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko)
fi

"${DISKO[@]}" \
  --flake ".#asus-tuf" \
  --disk main "$MAIN_DISK" \
  --disk home "$HOME_DISK"

echo
echo "Install complete. You can now reboot."
