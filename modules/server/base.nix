{ pkgs, ... }:

# Common baseline imported by every host: nix flakes + weekly garbage collection and store
# optimisation (keeps /nix/store from creeping toward the disk cap on long-lived hosts),
# /tmp wiped on boot, a handful of essential CLI tools, UTC + en_US.UTF-8, key-only
# OpenSSH with root login disabled, and a journald disk cap so a chatty service can't
# slowly fill the (small) root partition on a VM. Also pulls in the dynamic /etc/motd
# splash and the zsh login shell so every host gets the same interactive baseline.

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  boot.tmp.cleanOnBoot = true;

  environment.systemPackages = with pkgs; [
    tmux
    htop
    git
    vim
  ];

  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
