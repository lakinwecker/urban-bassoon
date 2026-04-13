#!/usr/bin/env bash
# Inspects the installed system's initrd from the live ISO to see which
# kernel modules actually landed in it. Run after an install attempt
# that won't boot. Safe to re-run.
set -euo pipefail

MAIN_LUKS="/dev/disk/by-partlabel/disk-main-luks"
MAIN_ESP="/dev/disk/by-partlabel/disk-main-ESP"

if [ ! -e "$MAIN_LUKS" ]; then
  echo "ERROR: $MAIN_LUKS not found — is the installed drive connected?" >&2
  exit 1
fi

# 1. Open cryptroot if not already open
if [ ! -e /dev/mapper/cryptroot ]; then
  echo "==> Unlocking cryptroot"
  sudo cryptsetup open "$MAIN_LUKS" cryptroot
else
  echo "==> cryptroot already open"
fi

# 2. Mount ESP if not already mounted
sudo mkdir -p /mnt/esp
if ! mountpoint -q /mnt/esp; then
  echo "==> Mounting ESP at /mnt/esp"
  sudo mount "$MAIN_ESP" /mnt/esp
else
  echo "==> /mnt/esp already mounted"
fi

# 3. Find the UKI .efi file (largest = the kernel+initrd UKI)
UKI=$(sudo find /mnt/esp -type f -name '*initrd*.efi' | head -1)
if [ -z "$UKI" ]; then
  # Fall back to the largest .efi
  UKI=$(sudo find /mnt/esp -type f -name '*.efi' -exec du -b {} + | sort -rn | head -1 | awk '{print $2}')
fi
echo "==> UKI: $UKI"

# 4. Ensure objcopy is available
if ! command -v objcopy >/dev/null; then
  echo "==> objcopy not on PATH, pulling binutils from nixpkgs"
  OBJCOPY=$(nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths nixpkgs#binutils 2>/dev/null)/bin/objcopy
else
  OBJCOPY=$(command -v objcopy)
fi
echo "==> objcopy: $OBJCOPY"

# 5. Extract the embedded .initrd section from the UKI
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
sudo cp "$UKI" "$TMP/uki.efi"
"$OBJCOPY" -O binary --only-section=.initrd "$TMP/uki.efi" "$TMP/initrd.img"

echo
echo "==> Initrd file type:"
file "$TMP/initrd.img"

echo
echo "==> Extracting cpio listing"
# NixOS UKI initrds are usually zstd. Try zstd first, fall back to raw.
if zstd -dc "$TMP/initrd.img" > "$TMP/initrd.cpio" 2>/dev/null; then
  echo "    (zstd decompression OK)"
else
  echo "    (not zstd, using raw)"
  cp "$TMP/initrd.img" "$TMP/initrd.cpio"
fi

# NixOS stacks initrds: microcode.cpio + main.cpio concatenated.
# Extract everything cpio can read, skipping past anything it doesn't.
mkdir -p "$TMP/extract"
cd "$TMP/extract"
cpio -idm --no-absolute-filenames < "$TMP/initrd.cpio" 2>/dev/null || true
cd - >/dev/null

echo
echo "==> Searching for nvme / vmd in the extracted initrd:"
find "$TMP/extract" -type f \( -name '*nvme*' -o -name '*vmd*' \) 2>/dev/null | sed "s|$TMP/extract||" | head -40

echo
echo "==> All kernel modules present in initrd:"
find "$TMP/extract" -type f -name '*.ko*' 2>/dev/null | sed "s|$TMP/extract||" | sort | head -60

echo
echo "==> crypttab / systemd cryptsetup units (if any):"
find "$TMP/extract" -type f \( -name 'crypttab*' -o -name 'systemd-cryptsetup*' -o -name '*.mount' -o -name '*cryptsetup*' \) 2>/dev/null | sed "s|$TMP/extract||" | head -20

echo
echo "==> /etc/initrd-release (for NixOS generation info):"
sudo cat "$TMP/extract/etc/initrd-release" 2>/dev/null || echo "(not present)"

echo
echo "Done. Temp files at $TMP (will be cleaned up on exit)."
