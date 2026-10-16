{ config, pkgs, systemd, ... }:

{
  systemd.user.services.populate-netrc = {
    description = "Populate .netrc from secret service";
    wantedBy = [ "default.target" ];
    after = [ "gnome-keyring-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "populate-netrc" ''
        secret-tool lookup service mymachine > ~/.netrc
        chmod 600 ~/.netrc
      '';
    };
  };
}
