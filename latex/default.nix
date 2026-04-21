{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.texlive.combine {
      inherit (pkgs.texlive)
        scheme-medium
        ebgaramond
        marginnote
        sectsty
        parskip
        ulem
        relsize
        setspace
        ;
    })
  ];

  fonts.packages = with pkgs; [
    google-fonts
  ];
}
