{ modulesPath, lib, ... }:

# Baseline for any QEMU/KVM guest (UTM, Proxmox, …): pulls in the upstream qemu-guest profile,
# enables qemu-guest-agent (so the hypervisor can read the guest's IP, freeze for snapshots, etc.),
# and uses systemd-boot on EFI. `useDHCP` is `mkDefault` so hosts with static networking (junction) override it.
# `console=ttyS0` belongs here (not just on the template image) so that clones — which get
# `nixos-rebuild switch`'d after creation — keep a working serial console for `qm terminal`.

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot.loader.systemd-boot.enable = true;
  # systemd-boot keeps every generation by default, which fills the small ESP.
  boot.loader.systemd-boot.configurationLimit = 6;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "console=tty1" "console=ttyS0,115200" ];

  services.qemuGuest.enable = true;

  networking.useDHCP = lib.mkDefault true;
}
