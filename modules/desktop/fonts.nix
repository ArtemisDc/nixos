{ config, pkgs, fonts, ...}:

{
  fonts = {
    packages = with pkgs; [
      #icon pack for waybar
      font-awesome
      nerd-fonts.sauce-code-pro
      symbola
    ];
    fontconfig.defaultFonts = {
      monospace = [ "SauceCodePro Nerd Font Mono" ];
      sansSerif = [ "SauceCodePro Nerd Font" ];
      serif     = [ "SauceCodePro Nerd Font" ];
      emoji     = [ "Symbola" ];
    };
  };
}
