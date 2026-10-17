{ ... }:

# Immutable users with `niki` as the sole admin account (wheel + passwordless sudo, ssh key only).
# `mutableUsers = false` means `useradd`/`passwd` won't survive a rebuild — manage accounts here, not at runtime.
# Root is locked (`hashedPassword = "!"`) so the only way in is via emz + sudo.

{
  users.mutableUsers = false;

  users.users.root.hashedPassword = "!";

  users.users.niki = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMDrrIVN9orKfO+f7dFme8fPjqnqxLDJtBHs6JNTINxq niki@pc-niki"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsEpF0KG6ehLZn5Mi9MJ1+3Gib3H9oz8ri9j9oE4zEE niki@laptop-niki"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
