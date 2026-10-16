{ config, pkgs, ... }:
{
  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  networking.networkmanager.ensureProfiles = {
    # Contains EDUROAM_USER=... and EDUROAM_PASSWORD=...
    # Keep this out of the Nix store (agenix, sops-nix, or a root-only file).
    environmentFiles = [ "/home/niki/.config/nixos/eduroam/eduroam.env" ];

    profiles.eduroam = {
      connection = {
        id = "eduroam";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        ssid = "eduroam";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-eap";
        proto = "rsn";
        pairwise = "ccmp";
        group = "ccmp";
      };
      "802-1x" = {
        eap = "peap;";
        phase2-auth = "mschapv2";
        identity = "$EDUROAM_USER";            # e.g. abc@tu-berlin.de
        anonymous-identity = "wlan@tu-berlin.de";
        password = "$EDUROAM_PASSWORD";
        password-flags = 0;                    # stored in the profile (root-only file)
        ca-cert = "${./tu-berlin-eduroam-ca.pem}";
        domain-match = "radius-01.tu-berlin.de;radius-02.tu-berlin.de";
      };
      ipv4.method = "auto";
      ipv6 = {
        method = "auto";
        addr-gen-mode = "stable-privacy";
      };
    };
  };
}
