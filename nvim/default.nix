{ pkgs, ... }: {
  environment.etc."nvim/init.lua".source = ./init.lua;
  environment.etc."nvim/lua/config/options.lua".source = ./lua/config/options.lua;
  environment.etc."nvim/lua/plugins/init.lua".source = ./lua/plugins/init.lua;

  system.activationScripts.nvimConfig = {
    deps = [ "userDirs" ];
    text = ''
      mkdir -p /home/nixos/.config/nvim/lua/config
      mkdir -p /home/nixos/.config/nvim/lua/plugins
      ln -sf /etc/nvim/init.lua /home/nixos/.config/nvim/init.lua
      ln -sf /etc/nvim/lua/config/options.lua /home/nixos/.config/nvim/lua/config/options.lua
      ln -sf /etc/nvim/lua/plugins/init.lua /home/nixos/.config/nvim/lua/plugins/init.lua
      chown -R nixos:users /home/nixos/.config/nvim
    '';
  };
}
