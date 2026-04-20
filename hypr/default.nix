# Force rebuild
{ pkgs, lib, username, hyprland, hyprgrass ? null, hyprHostConfig ? "", hyprWallpaper ? ./wallpaper.jpg, ... }:
let
  hyprgrassEnabled = hyprgrass != null;
in {
  imports = [ hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common.default = [ "hyprland" "gtk" ];
      hyprland.default = [ "hyprland" "gtk" ];
    };
  };

  environment.etc."hypr/plugins/hyprgrass.so" = lib.mkIf hyprgrassEnabled {
    source = "${hyprgrass.packages.${pkgs.system}.default}/lib/libhyprgrass.so";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${hyprland.packages.${pkgs.system}.hyprland}/bin/start-hyprland";
        user = username;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    rofi
    nwg-drawer
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
    # HyprPanel recommended deps
    libgtop
    dart-sass
    gvfs
    gtksourceview3
    libsoup_3
    # HyprPanel optional deps
    hyprsunset
    pywal
    awww
    matugen
    grimblast
    hyprpicker
    btop
    bluez
    bluez-tools
    blueman
    pavucontrol
    power-profiles-daemon
  ];

  environment.etc."hypr/scripts/mac-shortcut.sh" = {
    source = ./scripts/mac-shortcut.sh;
    mode = "0755";
  };

  environment.etc."hypr/rofi-tokyonight.rasi".source = ./rofi-tokyonight.rasi;
  environment.etc."hypr/nwg-drawer.css".source = ./nwg-drawer.css;

  environment.etc."hypr/hyprland.conf".text =
    builtins.readFile ./hyprland.conf
    + lib.optionalString hyprgrassEnabled (builtins.readFile ./hyprgrass.conf)
    + "\n# Per-host overrides\n" + hyprHostConfig;
  environment.etc."hypr/hypridle.conf".source = ./hypridle.conf;
  environment.etc."hypr/hyprlock.conf".source = ./hyprlock.conf;
  environment.etc."wallpaper.jpg".source = hyprWallpaper;
  environment.etc."hyprpanel/config.json".source = ./hyprpanel-config.json;
  environment.etc."btop/btop.conf".source = ./btop.conf;
  environment.etc."avatar.png".source = ./avatar.png;

  system.activationScripts.hyprConfig = {
    deps = [ "users" ];
    text = ''
      install -d -o ${username} -g users /home/${username}/.config
      install -d -o ${username} -g users /home/${username}/.config/hypr
      install -d -o ${username} -g users /home/${username}/.config/hyprpanel
      install -d -o ${username} -g users /home/${username}/.config/hyprpanel/styles
      install -d -o ${username} -g users /home/${username}/.config/btop
      ln -sf /etc/btop/btop.conf /home/${username}/.config/btop/btop.conf
      chown -h ${username}:users /home/${username}/.config/btop/btop.conf
      ln -sf /etc/hypr/hyprland.conf /home/${username}/.config/hypr/hyprland.conf
      ln -sf /etc/hypr/hypridle.conf /home/${username}/.config/hypr/hypridle.conf
      ln -sf /etc/hypr/hyprlock.conf /home/${username}/.config/hypr/hyprlock.conf
      chown -h ${username}:users /home/${username}/.config/hypr/hyprland.conf /home/${username}/.config/hypr/hypridle.conf /home/${username}/.config/hypr/hyprlock.conf
      install -m 0644 -o ${username} -g users /etc/hyprpanel/config.json /home/${username}/.config/hyprpanel/config.json
      install -m 0644 -o ${username} -g users /etc/avatar.png /home/${username}/.face.icon
      install -m 0644 -o ${username} -g users /etc/wallpaper.jpg /home/${username}/.config/background
    '';
  };
}
