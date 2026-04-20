{ pkgs, username, ... }: {
  environment.systemPackages = with pkgs; [
    ghostty
  ];

  environment.etc."ghostty/config".source = ./config;

  system.activationScripts.ghosttyConfig = {
    deps = [ "users" ];
    text = ''
      install -d -o ${username} -g users /home/${username}/.config
      install -d -o ${username} -g users /home/${username}/.config/ghostty
      ln -sf /etc/ghostty/config /home/${username}/.config/ghostty/config
      chown -h ${username}:users /home/${username}/.config/ghostty/config
    '';
  };
}
