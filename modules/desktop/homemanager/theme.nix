{ pkgs, ... }: {
  home.packages = with pkgs; [
    gnome-themes-extra
    adwaita-icon-theme
    adwaita-qt
    adwaita-qt6
    xdg-desktop-portal-gtk
  ];

  # Portals, libadwaita, Firefox and Electron read this
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Remove gtk window decoration buttons
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = ":";
  gtk.gtk3.extraConfig.gtk-decoration-layout = ":";
  gtk.gtk4.extraConfig.gtk-decoration-layout = ":";



  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # Portal configuration, so the GTK portal answers the dark/light setting
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    config.common = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };
}
