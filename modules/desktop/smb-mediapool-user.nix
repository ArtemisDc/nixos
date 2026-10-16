{ config, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
  fileSystems."/home/niki/mediapool" = {
    device = "//nas.trester.net/mediapool";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in [
      "${automount_opts},credentials=/etc/secrets/smb"
      "credentials=/etc/secrets/smb"
      "uid=1000"          # ← your user's UID (run `id -u` to check)
      "gid=100"           # ← your user's GID (run `id -g` to check)
      "file_mode=0755"
      "dir_mode=0755"
    ];
  }; 
}
