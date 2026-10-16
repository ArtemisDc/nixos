{ config, pkgs, inputs, ...}:

{
  environment.systemPackages = with pkgs; [
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    dunst
    waybar
    # dmenue
    rofi

    # clipboard history
    cliphist
    wl-clipboard

    # needed for music playback via jellyfin
    mopidy

    #needed for setting gtk setting for themes etc
    glib

    #themes
    quintom-cursor-theme
    gnome-themes-extra

    #default programs
    ranger
    neovim
    firefox
    iamb
    imv
    zathura
  ];


  environment.variables = {
    XCURSOR_THEME = "Quintom_Ink";
    XCURSOR_SIZE = "24";
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  #force wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # nixos cachix server to not compile hyprland
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    # Required so non-root users are allowed to use the above substituter/keys.
    # Use @wheel for all sudo users, or list your username explicitly.
    trusted-users = ["root" "@wheel"];
  };

  # make dark themes in homemanager work
  programs.dconf.enable = true;
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];


}
