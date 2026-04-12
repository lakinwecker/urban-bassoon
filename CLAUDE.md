# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A flake-based set of NixOS configurations for the user's personal machines, plus matching live installer ISOs. Targets: Surface Pro 9 (Intel), an AMD laptop, and an AMD desktop. The same flake produces both the bootable installer and the installed system for each machine.

## Build

```bash
# Build all three installer ISOs
./build.sh

# Build a single ISO (surface-iso | laptop-iso | desktop-iso)
nix build .#nixosConfigurations.surface-iso.config.system.build.isoImage

# Build (don't install) an installed-system config to check evaluation
nix build .#nixosConfigurations.surface.config.system.build.toplevel
```

ISO output lands in `./result-<host>/iso/nixos-*.iso`. Write to USB with `dd`. Boot menu on SP9: hold Volume Down + Power.

## Install onto a machine

The installer ISO copies the flake to `/iso/flake`. From the live environment:

```bash
sudo disko-install --flake /iso/flake#surface --disk main /dev/disk/by-id/nvme-...
```

`disko-config.nix` defines the partition layout (512M EFI + LUKS btrfs with `/`, `/home`, `/nix` subvolumes). LUKS password is read from `/tmp/disk-password` at install time. See `INSTALL.md`.

## Architecture

`flake.nix` is the single source of truth and defines six `nixosConfigurations`:

- `surface` / `surface-iso` — Surface Pro 9, hostname `harry`
- `laptop` / `laptop-iso` — AMD laptop
- `desktop` / `desktop-iso` — AMD desktop

These are composed from three module lists in `flake.nix`:

- `commonModules` — shared base: imports every top-level config directory (`./hypr`, `./ghostty`, `./nvim`, `./fish`, `./starship`, `./bin`, `./zellij`) plus `nebula.nix` and `syncthing.nix`, then defines pipewire, networking, fonts, ssh, lan-mouse user service, and the shared package set.
- `surfaceModules` — `commonModules` + `nixos-hardware.microsoft-surface-pro-intel` + Surface-specific kernel modules, hibernate/s2idle tuning, and ithc/iptsd resume hooks.
- `laptopModules` / `desktopModules` — `commonModules` + AMD CPU/GPU hardware modules, with TLP power profiles on the laptop variant.

Each `*-iso` config layers `installation-cd-minimal.nix` on top and embeds the flake at `/flake` in the ISO. Each installed config layers `disko-config.nix` and sets `boot.loader.systemd-boot`, `networking.hostName`, and an initial user.

When adding a setting that should apply everywhere, put it in `commonModules`. When it's hardware-specific, put it in the matching `surfaceModules` / `laptopModules` / `desktopModules` block. Avoid duplicating across the three host variants.

The top-level config directories (`hypr/`, `nvim/`, `fish/`, etc.) are NixOS modules — each exposes a `default.nix` that's imported by `commonModules`. Edit these to change desktop / editor / shell behavior across all hosts at once.

## Surface Pro 9 specifics

- Kernel: `hardware.microsoft-surface.kernelVersion = "stable"`. ZFS is force-disabled — incompatible with the surface kernel. Rust kernel support is force-disabled via a kernel patch.
- Type Cover at the LUKS prompt requires the `pinctrl_tigerlake`, `intel_lpss*`, `surface_aggregator*`, `surface_hid*`, `hid_multitouch`, and `ithc` modules in `boot.initrd.kernelModules`. Don't remove these without testing the LUKS prompt.
- `surface_gpe` is blacklisted — it caused wake failures with the Type Cover closed during suspend.
- SP9 firmware only supports s2idle (no S3). `mem_sleep_default=s2idle` and `i915.enable_psr=0` in `boot.kernelParams` are load-bearing for low-power residency.
- Hibernate uses a btrfs swapfile at `/swap/swapfile` with `resume_offset=39068928`. If you resize/recreate the swapfile, recompute the offset. See `HIBERNATE-SETUP.md`.
- ithc loses state across hibernate — `powerManagement.powerUpCommands` reloads it and restarts iptsd. Don't drop these.

## lan-mouse (KVM)

Runs as a per-user systemd service from `commonModules`. Listens on TCP/UDP **4343** (4242 is taken by nebula). The `surface` host writes a `~/.config/lan-mouse/config.toml` via an activation script pointing at `trunkie.local`. See `lan-mouse-client.md` / `lan-mouse-server.md`.

## Conventions

- ISO builds use `gzip -Xcompression-level 1` for faster (larger) images during dev.
- `iso-packages.nix` is shared between installer and installed configs — packages added there land in both.
- Kernel rebuilds are cached; only config changes trigger them.
