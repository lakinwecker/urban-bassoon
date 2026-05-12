{ lib, ... }:
{
  # Trunkie — 4-disk RAID1 layout (Threadripper 1950X desktop)
  #
  # Root mirror (btrfs RAID1):
  #   root0 (nvme0n1, 224G) + root1 (sda, 224G)
  #   ESP on root0 only (can reinstall boot from mirror if needed)
  #   Both LUKS-encrypted; btrfs -d raid1 -m raid1 across both
  #   Subvolumes: /, /nix, /swap
  #
  # Home mirror (btrfs RAID1):
  #   home0 (nvme1n1, 1.9T) + home1 (new 2TB NVMe, replacing nvme2n1)
  #   Both LUKS-encrypted; btrfs -d raid1 -m raid1 across both
  #   Subvolume: /home
  #   Unlocked via keyfile on root (single password prompt at boot)
  #
  # Install command (override device paths with by-id):
  #   ./install.sh trunkie --disk root0 /dev/disk/by-id/... \
  #                        --disk root1 /dev/disk/by-id/... \
  #                        --disk home0 /dev/disk/by-id/... \
  #                        --disk home1 /dev/disk/by-id/...

  disko.devices = {
    disk = {
      root0 = {
        # Primary root NVMe (224G) — has ESP
        device = lib.mkDefault "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot0";
                passwordFile = "/tmp/disk-password";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "root" "-d" "raid1" "-m" "raid1" "/dev/mapper/cryptroot1" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      mountOptions = [ "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };

      root1 = {
        # Secondary root SATA SSD (224G) — RAID1 partner
        device = lib.mkDefault "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot1";
                passwordFile = "/tmp/disk-password";
                settings.allowDiscards = true;
                # No filesystem — added to root btrfs via extraArgs above
              };
            };
          };
        };
      };

      home0 = {
        # Primary home NVMe (1.9T)
        device = lib.mkDefault "/dev/nvme1n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypthome0";
                passwordFile = "/tmp/disk-password";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "home" "-d" "raid1" "-m" "raid1" "/dev/mapper/crypthome1" ];
                  subvolumes = {
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };

      home1 = {
        # Secondary home NVMe (2T) — RAID1 partner
        device = lib.mkDefault "/dev/nvme2n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypthome1";
                passwordFile = "/tmp/disk-password";
                settings.allowDiscards = true;
                # No filesystem — added to home btrfs via extraArgs above
              };
            };
          };
        };
      };
    };
  };
}
