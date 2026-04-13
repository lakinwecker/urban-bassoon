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

# 5. Extract the initrd payload. The file may be either:
#    (a) a true UKI — PE/COFF with an embedded .initrd section
#    (b) a raw zstd-compressed cpio with a .efi extension (NixOS often does this)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
sudo cp "$UKI" "$TMP/uki.bin"

# Magic-byte detection (no `file` on live ISO)
magic_hex() { head -c 4 "$1" | od -An -tx1 | tr -d ' \n'; }

UKI_MAGIC=$(magic_hex "$TMP/uki.bin")
echo
echo "==> UKI size: $(stat -c %s "$TMP/uki.bin") bytes"
echo "==> UKI first 64 bytes (hex):"
head -c 64 "$TMP/uki.bin" | od -An -tx1z | head
echo "==> UKI first 4 bytes: $UKI_MAGIC"

case "$UKI_MAGIC" in
  4d5a*)  # "MZ" — PE/COFF executable
    echo "==> PE detected (MZ), extracting .initrd section via objcopy"
    "$OBJCOPY" -O binary --only-section=.initrd "$TMP/uki.bin" "$TMP/initrd.img"
    ;;
  28b52ffd)  # zstd magic
    echo "==> Raw zstd detected, decompressing"
    zstd -dc "$TMP/uki.bin" > "$TMP/initrd.img"
    ;;
  1f8b*)  # gzip magic
    echo "==> Raw gzip detected, decompressing"
    gzip -dc "$TMP/uki.bin" > "$TMP/initrd.img"
    ;;
  3037*)  # "07" — cpio newc magic "070701" or "070702"
    echo "==> Raw cpio detected (no decompression needed)"
    cp "$TMP/uki.bin" "$TMP/initrd.img"
    ;;
  *)
    echo "==> Unknown magic $UKI_MAGIC — trying as-is, may fail"
    cp "$TMP/uki.bin" "$TMP/initrd.img"
    ;;
esac

INITRD_MAGIC=$(magic_hex "$TMP/initrd.img")
echo "==> Extracted initrd first 4 bytes: $INITRD_MAGIC"

cp "$TMP/initrd.img" "$TMP/initrd.cpio"

echo
echo "==> First cpio archive (likely microcode):"
cpio -t < "$TMP/initrd.cpio" 2>&1 | head -5 || true

# Find the byte offset of the second archive. NixOS concatenates
# microcode.cpio + main.cpio. cpio -t reports "N blocks" for the first;
# we use that to dd past it and reveal whatever comes next (usually
# a compressed second initrd).
FIRST_BLOCKS=$(cpio -t < "$TMP/initrd.cpio" 2>&1 | awk '/blocks$/ {print $1; exit}')
echo "==> First archive: $FIRST_BLOCKS blocks (512 bytes each = $((FIRST_BLOCKS * 512)) bytes)"

dd if="$TMP/initrd.cpio" of="$TMP/second.bin" bs=512 skip="$FIRST_BLOCKS" status=none

SECOND_SIZE=$(stat -c %s "$TMP/second.bin")
echo "==> Second payload size: $SECOND_SIZE bytes"
if [ "$SECOND_SIZE" -eq 0 ]; then
  echo "==> No second archive. Only microcode was present in the UKI!"
  echo "    This means the real initrd is a SEPARATE file in the ESP."
  echo
  echo "==> Other candidate files in /mnt/esp:"
  sudo find /mnt/esp -type f | xargs -I{} sudo stat -c '%s  %n' {} | sort -rn | head -20
  exit 0
fi

SECOND_MAGIC=$(head -c 4 "$TMP/second.bin" | od -An -tx1 | tr -d ' \n')
echo "==> Second payload first 4 bytes: $SECOND_MAGIC"

case "$SECOND_MAGIC" in
  28b52ffd) echo "==> zstd — decompressing"; zstd -dc "$TMP/second.bin" > "$TMP/real.cpio" ;;
  1f8b*)    echo "==> gzip — decompressing"; gzip -dc "$TMP/second.bin" > "$TMP/real.cpio" ;;
  fd377a58) echo "==> xz — decompressing"; xz -dc "$TMP/second.bin" > "$TMP/real.cpio" ;;
  04224d18) echo "==> lz4 — decompressing"; lz4 -dc "$TMP/second.bin" > "$TMP/real.cpio" ;;
  3037*)    echo "==> raw cpio"; cp "$TMP/second.bin" "$TMP/real.cpio" ;;
  *)        echo "==> unknown magic $SECOND_MAGIC, trying as-is"; cp "$TMP/second.bin" "$TMP/real.cpio" ;;
esac

echo
echo "==> Extracting real initrd to $TMP/extract"
mkdir -p "$TMP/extract"
cd "$TMP/extract"
cpio -idm --no-absolute-filenames < "$TMP/real.cpio" 2>&1 | tail -5 || true
cd - >/dev/null
echo "==> Extracted file count: $(find "$TMP/extract" -type f 2>/dev/null | wc -l)"

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
