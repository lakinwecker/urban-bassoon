#!/usr/bin/env bash
set -euo pipefail

all=("surface" "laptop" "desktop" "asus-tuf")

usage() {
  echo "Usage: $0 [host...]" >&2
  echo "  hosts: ${all[*]} (default: all)" >&2
  exit 1
}

if [ $# -eq 0 ]; then
  configs=("${all[@]}")
else
  configs=("$@")
  for cfg in "${configs[@]}"; do
    found=0
    for valid in "${all[@]}"; do
      [ "$cfg" = "$valid" ] && found=1 && break
    done
    [ $found -eq 1 ] || { echo "Unknown host: $cfg" >&2; usage; }
  done
fi

for cfg in "${configs[@]}"; do
  echo "Building ${cfg}-iso..."
  nix build ".#nixosConfigurations.${cfg}-iso.config.system.build.isoImage" -o "result-${cfg}"
  echo "Done: result-${cfg}"
done
