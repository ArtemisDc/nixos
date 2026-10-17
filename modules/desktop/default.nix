{ config, pkgs, inputs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hyprland.nix
      ./fonts.nix
      ./neovim.nix
      ./coding
      ./communication
      ./eduroam
      ./smb-mediapool-user.nix
      ./bluetooth.nix
    ];
    
  home-manager.users.niki = import ./homemanager;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };


  #allow pipewire to get realtime scheduling priority? idk claude said so
  security.rtkit.enable = true;

  users.users.niki = {
    isNormalUser = true;
    description = "Nikola Trester";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
	  pkgs.htop
	  pkgs.git
    pkgs.gnumake
	  pkgs.hyfetch
    pkgs.fastfetch
	  pkgs.kitty
	  pkgs.firefox
	  pkgs.keepassxc
    pkgs.discord
    # potentially neet organizing 
    pkgs.unzip
  ];

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  environment.sessionVariables.SUDO_EDITOR = "nvim";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.openFirewall = true;

  system.stateVersion = "25.11";

}
