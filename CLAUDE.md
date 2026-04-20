# CLAUDE.md

Flake-based NixOS configurations for personal machines, plus matching live installer ISOs.

## Machines

| Host | Hardware | Desktop | User |
|------|----------|---------|------|
| harry | Surface Pro 9 (Intel) | Hyprland | lakin |
| sebbers | AMD laptop | Hyprland | lakin |
| trunkie | Threadripper desktop | Hyprland | lakin |
| roach | Asus TUF F16 (Intel + NVIDIA) | Hyprland | lakin |
| cornfield | ThinkPad T460 (Skylake) | XFCE | clown |

## Build & Install

See [docs/build.md](docs/build.md).

## Architecture

`flake.nix` defines 10 `nixosConfigurations` (5 hosts x {iso, installed}) via `mkIso` and `mkInstalled` helpers.

### Key parameters

- `username` — passed via `specialArgs`, defaults to `"lakin"`. Threaded through all modules.
- `hyprland` / `hyprgrass` / `hyprHostConfig` / `hyprWallpaper` — Hyprland-specific, passed via `specialArgs`.
- `xfceWallpaper` — XFCE wallpaper, passed via `specialArgs` for cornfield.
- `ollamaCuda` — enables CUDA ollama on roach.

### Directory layout

```
common/              Shared config (networking, desktop, audio, packages, user)
hosts/<name>/        Hardware-specific config per machine
hypr/                Hyprland module (added per-host, not via common/)
xfce/                XFCE module (cornfield only)
ghostty/ nvim/ fish/ Program modules (imported by common/default.nix)
starship/ bin/ zellij/ ai/
```

### Module composition

- `commonModules = [ ./common ]` — imports themed sub-modules + program directories (not desktop environment).
- Desktop environment (`./hypr` or `./xfce`) is added per-host in the host's module list.
- Each host adds `nixos-hardware` modules + `./hosts/<name>`.
- Shared settings go in `common/*.nix`. Hardware-specific settings go in `hosts/<name>/default.nix`.

## harry (Surface Pro 9) specifics

- Type Cover at LUKS prompt needs `pinctrl_tigerlake`, `intel_lpss*`, `surface_aggregator*`, `surface_hid*`, `hid_multitouch`, `ithc` in `boot.initrd.kernelModules`. Don't remove without testing.
- `surface_gpe` is blacklisted (wake failures with Type Cover closed).
- Firmware only supports s2idle. `mem_sleep_default=s2idle` and `i915.enable_psr=0` are load-bearing.
- Hibernate: btrfs swapfile at `/swap/swapfile` with `resume_offset=39068928`. Recompute offset if swapfile changes.
- `surface-touchscreen-resume` service reloads ithc after hibernate. Don't drop it.

## Conventions

- ISO builds use `gzip -Xcompression-level 1` for faster (larger) images during dev.
- `iso-packages.nix` is shared between installer and installed configs.
- lan-mouse listens on TCP/UDP **4343** (4242 is taken by nebula).
