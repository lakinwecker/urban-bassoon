{ ... }:
{
  imports = [
    ./networking.nix
    ./desktop.nix
    ./audio.nix
    ./packages.nix
    ./user.nix
    ../ghostty
    ../nvim
    ../fish
    ../nushell
    ../starship
    ../bin
    ../zellij
    ../ai
  ];
}
