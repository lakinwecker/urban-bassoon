# Force rebuild
{ pkgs, hyprland, hyprgrass, ... }:
let
  hyprgrassPlugin = hyprgrass.packages.${pkgs.system}.default;
in {
  imports = [ hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # Make plugin path available
  environment.etc."hypr/plugins/hyprgrass.so".source = "${hyprgrassPlugin}/lib/libhyprgrass.so";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "Hyprland";
        user = "nixos";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    hyprshell
    onagre
    bibata-cursors
    hyprlock
    hypridle
    hyprpolkitagent
    hyprpanel
    playerctl
    brightnessctl
    wl-clipboard
    wtype
    grim
    slurp
    wf-recorder
    python3
    socat
    wvkbd
    iio-hyprland
    # Must-have utilities
    xdg-desktop-portal-gtk
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland
    # HyprPanel optional deps
    hyprsunset
    pywal
    swww
    matugen
    grimblast
    hyprpicker
    btop
    bluez
    bluez-tools
    networkmanagerapplet
    power-profiles-daemon
  ];

  environment.etc."hypr/hyprland.conf".source = ./hyprland.conf;
  environment.etc."hypr/hypridle.conf".source = ./hypridle.conf;
  environment.etc."hypr/hyprlock.conf".source = ./hyprlock.conf;
  environment.etc."wallpaper.jpg".source = ./wallpaper.jpg;
  environment.etc."hyprpanel/config.json".source = ./hyprpanel-config.json;
  environment.etc."hyprpanel/custom.css".source = ./hyprpanel-custom.css;
  environment.etc."avatar.png".source = ./avatar.png;

  system.activationScripts.hyprConfig = {
    deps = [ "userDirs" ];
    text = ''
      mkdir -p /home/nixos/.config/hypr
      mkdir -p /home/nixos/.config/hyprpanel/styles
      ln -sf /etc/hypr/hyprland.conf /home/nixos/.config/hypr/hyprland.conf
      ln -sf /etc/hypr/hypridle.conf /home/nixos/.config/hypr/hypridle.conf
      ln -sf /etc/hypr/hyprlock.conf /home/nixos/.config/hypr/hyprlock.conf
      # Force copy hyprpanel config (overwrite any existing)
      cp -f /etc/hyprpanel/config.json /home/nixos/.config/hyprpanel/config.json
      cp -f /etc/hyprpanel/custom.css /home/nixos/.config/hyprpanel/styles/custom.css
      # User avatar
      cp -f /etc/avatar.png /home/nixos/.face.icon
      chown nixos:users /home/nixos/.face.icon
      # Wallpaper for HyprPanel
      cp -f /etc/wallpaper.jpg /home/nixos/.config/background
      chown nixos:users /home/nixos/.config/background
      # Fix all hyprpanel permissions
      chown -R nixos:users /home/nixos/.config/hyprpanel
      chmod -R u+rw /home/nixos/.config/hyprpanel
    '';
  };
}
