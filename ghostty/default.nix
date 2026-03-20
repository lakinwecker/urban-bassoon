{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    ghostty
  ];

  environment.etc."ghostty/config".source = ./config;

  system.activationScripts.ghosttyConfig = ''
    mkdir -p /home/nixos/.config/ghostty
    ln -sf /etc/ghostty/config /home/nixos/.config/ghostty/config
  '';
}
