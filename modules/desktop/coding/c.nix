{ config, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    git
    gnumake
    gcc
    gdb
    valgrind
    cmake
  ];
}
