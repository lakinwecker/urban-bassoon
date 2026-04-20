{ pkgs, username, ... }:
{
  environment.etc."nushell-user/config.nu".source = ./config.nu;
  environment.etc."nushell-user/env.nu".source = ./env.nu;

  system.activationScripts.nushellConfig = {
    deps = [ "users" ];
    text = ''
      NU_CONFIG="/home/${username}/.config/nushell"
      if [ ! -d "$NU_CONFIG" ]; then
        mkdir -p "$NU_CONFIG"
        ln -sf /etc/nushell-user/config.nu "$NU_CONFIG/config.nu"
        ln -sf /etc/nushell-user/env.nu "$NU_CONFIG/env.nu"
        chown -R ${username}:users "$NU_CONFIG"
      fi
    '';
  };
}
