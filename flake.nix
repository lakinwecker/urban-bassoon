{
  description = "NixOS Surface Pro 9 installer ISO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprgrass = {
      url = "github:horriblename/hyprgrass";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, hyprland, hyprgrass, ... }: {
    nixosConfigurations.surface-iso = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit hyprland hyprgrass; };
      modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        nixos-hardware.nixosModules.microsoft-surface-pro-intel
        ./iso-packages.nix
        ./hypr
        ./kitty
        ./nvim
        ({ lib, pkgs, modulesPath, ... }: {
          imports = [
            (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
          ];

          boot.supportedFilesystems.zfs = lib.mkForce false;
          boot.kernelPatches = [{
            name = "disable-rust";
            patch = null;
            structuredExtraConfig = { RUST = lib.mkForce lib.kernel.no; };
          }];

          nixpkgs.config.allowUnfree = true;
          hardware.enableRedistributableFirmware = true;
          services.iptsd.enable = true;
          hardware.sensor.iio.enable = true;
          hardware.bluetooth.enable = true;
          services.blueman.enable = true;
          services.power-profiles-daemon.enable = true;
          services.upower.enable = true;

          networking.networkmanager.enable = true;
          networking.wireless.enable = false;

          time.timeZone = "America/Edmonton";
          time.hardwareClockInLocalTime = true;

          security.polkit.enable = true;
          security.rtkit.enable = true;
          services.pipewire = {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;
          };

          fonts.fontconfig.enable = true;
          fonts.fontDir.enable = true;
          fonts.packages = with pkgs; [
            nerd-fonts.fira-code
            nerd-fonts.inconsolata
            nerd-fonts.iosevka
            noto-fonts
            noto-fonts-color-emoji
            inconsolata
            iosevka
          ];

          hardware.graphics.enable = true;

          # Ensure user dirs exist with correct ownership
          users.users.nixos = {
            isNormalUser = true;
            home = "/home/nixos";
            createHome = true;
            extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
          };

          system.activationScripts.userDirs = {
            deps = [ "users" ];
            text = ''
              mkdir -p /home/nixos/.config/hyprpanel
              mkdir -p /home/nixos/.config/hyprshell
              chown -R nixos:users /home/nixos
            '';
          };

          isoImage.squashfsCompression = "gzip -Xcompression-level 1";
        })
      ];
    };
  };
}
