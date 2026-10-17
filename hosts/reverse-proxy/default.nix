{ ... }:

# Example Proxmox VM running modules/caddy-reverse-proxy.nix, written up as a template for a
# friend's setup — not part of the emz tailnet, so no tailscale.nix, and no auto-upgrade.nix
# (that tracks this repo's main). The domain, LAN prefix and upstreams below are placeholders.
#
# Outside Nix: give the VM a fixed LAN address (DHCP reservation), forward TCP 443 (only) on the
# router to it, proxy the vhost records through Cloudflare with SSL mode "Full (strict)", and
# write the Cloudflare API token to /var/lib/caddy/cloudflare-api-token before the first start.
# For LAN clients to skip the Cloudflare round-trip, have the LAN resolver answer the vhost names
# with this VM's address; without that they hairpin through Cloudflare, which also works.
#
# Sizing: 1 core and 1 GiB is plenty for Caddy; 16 GiB OS disk from the template.

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/server/base.nix
    ../../modules/server/users.nix
    ../../modules/server/qemu-guest.nix
    ../../modules/server/caddy-reverse-proxy.nix
  ];

  modules.caddyReverseProxy = {
    enable = true;
    acmeEmail = "nt@trester.net";
    lanSubnets = [ 
      "192.168.10.0/24" 
      "192.168.30.0/24"
      "192.168.159.0/24"
    ];
    virtualHosts = {
      "radarr.trester.net".upstream = "http://radarr.int.trester.net:7878";
      "jellyfin.trester.net" = { upstream = "http://jellyfin.int.trester.net:80"; public = false; };
    };
  };

  system.stateVersion = "26.05";
}
