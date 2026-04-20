{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [
    starship
  ];

  environment.etc."starship/starship.toml".source = ./starship.toml;

  system.activationScripts.starshipConfig = {
    deps = [ "users" ];
    text = ''
      STARSHIP_CONFIG="/home/${username}/.config/starship.toml"
      if [ ! -e "$STARSHIP_CONFIG" ]; then
        ln -sf /etc/starship/starship.toml "$STARSHIP_CONFIG"
        chown -h ${username}:users "$STARSHIP_CONFIG"
      fi
    '';
  };
}
