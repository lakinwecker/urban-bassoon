{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    texliveMedium
    eb-garamond
  ];
}
