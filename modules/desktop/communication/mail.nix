{ config, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    protonmail-bridge
    aerc
  ];
}
