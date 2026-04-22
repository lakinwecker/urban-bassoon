{ pkgs, lib, username, ... }:
{
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  # GNOME requires NetworkManager.
  # Priority 49 beats the mkForce (priority 50) in common/networking.nix.
  networking.networkmanager.enable = lib.mkOverride 49 true;
  networking.wireless.iwd.enable = lib.mkOverride 49 false;
  networking.useNetworkd = lib.mkOverride 49 false;
  systemd.network.enable = lib.mkOverride 49 false;

  environment.systemPackages = with pkgs; [
    gimp
    gnome-tweaks
  ];

  # Remove GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    totem
  ];
}
