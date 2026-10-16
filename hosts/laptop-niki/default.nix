{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop/default.nix
  ];
  
  environment.systemPackages = with pkgs; [
    kmonad
  ];

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbOptions = "compose:ralt";
  };

  services.kmonad = {
    enable = true;
    keyboards = {
      kMonad = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
	      config = builtins.readFile ./thinkpad_T14g4.kbd;
	    };
    };
  };
  #begin fix video streaming crash
  #https://claude.ai/share/955c5378-15e8-4d52-b63e-35a0c67ac9eb
  boot.kernelParams = [
    "amdgpu.runpm=0"           # Runtime PM was already failing (saw it in logs)
    "amdgpu.dc=1"              # Keep display core explicit
    "amdgpu.dcfeaturemask=0x8" # Disables PSR - the most likely freeze trigger during video
    "pcie_aspm=off"            # Belt and suspenders for PCIe power conflicts
    "amdgpu.gpu_recovery=1"
  ];

  boot.extraModprobeConfig = ''
    options ath11k_pci disable_oob_irq=1
  '';

  boot.kernel.sysctl."kernel.sysrq" = 1;
  #end fix video streaming crash

  powerManagement.enable = true;
  services.tlp.enable = true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
