# Hibernate Setup (Surface Pro 9)

Requires two rebuilds — first to create swap, second to set resume offset.

```bash
# Create swap subvolume (existing install only)
sudo mount /dev/mapper/cryptroot /mnt -o subvol=/
sudo btrfs subvolume create /mnt/swap
sudo umount /mnt

# First rebuild + reboot
sudo nixos-rebuild switch --flake .#surface && sudo reboot

# After reboot — get offset, paste into boot.kernelParams resume_offset in flake.nix
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile

# Second rebuild + reboot
sudo nixos-rebuild switch --flake .#surface && sudo reboot
```
