{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {nixpkgs, ...} @ inputs: 
  let
    mkHost = system: host: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; }; # this is the important part
      modules = [ ./hosts/${host} ];
    };
  in {
    nixosConfigurations = {
      laptop-niki = mkHost "x86_64-linux" "laptop-niki";
    };
  };
}
