{ pkgs, config, lib, ... }:

# Caddy as a TLS-terminating reverse proxy for services on the LAN. Every vhost is reachable
# from `lanSubnets` on 80/443; vhosts with `public = true` are additionally reachable from the
# internet via Cloudflare's proxy → router port-forward of WAN 443 → `publicPort` (8443) here.
#
# Public/private separation doesn't rest on one check. (1) Listener: only public vhosts are bound
# to `publicPort`, so a request arriving there for a private hostname, whatever its SNI or Host
# header, matches no route. (2) Firewall: `publicPort` admits only Cloudflare's published ranges,
# 80/443 only the LAN, everything else is dropped — so the origin can't be hit directly to bypass
# Cloudflare, and Cloudflare can't reach the LAN listener. (3) Each private vhost wraps all of its
# handling in a `remote_ip` match on `lanSubnets` (the direct peer, never a forwarded header) and
# aborts the connection otherwise; its extraConfig sits inside that block, so it can't route
# around the check. If the router SNATs the forward, public traffic arrives from a LAN address,
# misses the Cloudflare-only rule, and is dropped: public vhosts break, private ones stay closed.
#
# Cloudflare's SSL mode must be "Full (strict)". The WAN 443 → `publicPort` remap can be done
# by the router or by a Cloudflare Origin Rule (8443 is one of the ports Cloudflare proxies).
#
# Certificates come from Let's Encrypt via ACME DNS-01 against Cloudflare (caddy-dns/cloudflare
# plugin), so issuance needs no inbound port and works the same for LAN-only names. Private names
# need no public DNS record, but each still shows up in certificate transparency logs. The API
# token (Zone → DNS → Edit on the zone) is provisioned out-of-band at
# /var/lib/caddy/cloudflare-api-token (root, 0600) and handed to Caddy as a systemd credential;
# the Caddyfile reads it at runtime through Caddy's {file.*} placeholder.
#
# CF-Connecting-IP is trusted only on `publicPort` and only from Cloudflare source addresses;
# the resulting client IP goes upstream as X-Real-IP and into the access logs.
# `cloudflareRanges` mirrors https://www.cloudflare.com/ips/ — update it if that list changes.

let
  cfg = config.modules.caddyReverseProxy;
  anyPublic = lib.any (v: v.public) (lib.attrValues cfg.virtualHosts);
  port = toString cfg.publicPort;

  isV6 = lib.hasInfix ":";
  # nft rejects empty sets, so a family with no prefixes gets no rule at all.
  saddrRule = family: prefixes: rest:
    lib.optionalString (prefixes != [ ])
      "${family} saddr { ${lib.concatStringsSep ", " prefixes} } ${rest}\n";
  bothFamilies = prefixes: rest:
    saddrRule "ip" (lib.filter (p: !isV6 p) prefixes) rest
    + saddrRule "ip6" (lib.filter isV6 prefixes) rest;

  handling = vhost: ''
    encode zstd gzip

    reverse_proxy ${vhost.upstream} {
      header_up X-Real-IP {client_ip}
    }

    header -Server
    ${vhost.extraConfig}
  '';
in {
  options.modules.caddyReverseProxy = {
    enable = lib.mkEnableOption "Caddy reverse proxy for LAN services, some published via Cloudflare";

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "Contact address sent to Let's Encrypt for expiry notices.";
    };

    lanSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "192.168.1.0/24" "fd00::/64" ];
      description = ''
        Prefixes allowed to reach Caddy directly on 80/443 (IPv4 and/or IPv6), and the only
        peers private vhosts answer.
      '';
    };

    publicPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = ''
        Listener for public vhosts, open to `cloudflareRanges` only. The router forwards WAN
        443 here. Must differ from 443.
      '';
    };

    cloudflareRanges = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "173.245.48.0/20" "103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22"
        "141.101.64.0/18" "108.162.192.0/18" "190.93.240.0/20" "188.114.96.0/20"
        "197.234.240.0/22" "198.41.128.0/17" "162.158.0.0/15" "104.16.0.0/13"
        "104.24.0.0/14" "172.64.0.0/13" "131.0.72.0/22"
        "2400:cb00::/32" "2606:4700::/32" "2803:f800::/32" "2405:b500::/32"
        "2405:8100::/32" "2a06:98c0::/29" "2c0f:f248::/32"
      ];
      description = ''
        Cloudflare edge prefixes: the only sources allowed on `publicPort`, and the only
        peers whose CF-Connecting-IP header is trusted.
      '';
    };

    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          upstream = lib.mkOption {
            type = lib.types.str;
            example = "http://192.168.1.20:8080";
            description = "Backend Caddy proxies to (anything `reverse_proxy` accepts).";
          };
          public = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Also serve this vhost to the internet via Cloudflare on `publicPort`. When false
              it answers LAN peers only.
            '';
          };
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Extra Caddyfile directives for this site, e.g. request_body limits.";
          };
        };
      });
      default = { };
      example = {
        "jellyfin.example.com" = { upstream = "http://192.168.1.20:8096"; public = true; };
        "nas.example.com".upstream = "http://192.168.1.21:5000";
      };
      description = "Map of hostname → backend. Each gets its own DNS-01 certificate.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.publicPort != 443 && cfg.publicPort != 80;
      message = "modules.caddyReverseProxy.publicPort must differ from the LAN listeners (80, 443).";
    }];

    # extraInputRules is nftables-only; require the backend.
    networking.nftables.enable = true;

    networking.firewall.extraInputRules =
      bothFamilies cfg.lanSubnets ''tcp dport { 80, 443 } accept comment "Caddy from LAN"''
      + bothFamilies cfg.lanSubnets ''udp dport 443 accept comment "Caddy HTTP/3 from LAN"''
      + lib.optionalString anyPublic (bothFamilies cfg.cloudflareRanges
        ''tcp dport ${port} accept comment "Caddy public vhosts from Cloudflare"'');

    systemd.services.caddy.serviceConfig.LoadCredential =
      [ "cloudflare-api-token:/var/lib/caddy/cloudflare-api-token" ];

    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-xRJ5evsAJ2akg47j3Bt6YDXJOgX88B/rKNP50KSVyNY=";
      };
      # {$CREDENTIALS_DIRECTORY} is expanded when Caddy adapts the Caddyfile at (re)start, and
      # the plugin then resolves {file.…} itself, so the token never lands in the Nix store.
      # The provider goes in the global `dns` option, which bare `acme_dns` picks up, rather than
      # inline on `acme_dns`: that way it's loaded with the TLS app even when no ACME issuer is
      # in play, so a missing or malformed token stops Caddy at startup instead of at renewal.
      # trusted_proxies is scoped to the public listener; on 443 the client IP is the peer.
      globalConfig = ''
        dns cloudflare {file.{$CREDENTIALS_DIRECTORY}/cloudflare-api-token}
        acme_dns
      '' + lib.optionalString anyPublic ''

        servers :${port} {
          trusted_proxies static ${lib.concatStringsSep " " cfg.cloudflareRanges}
          client_ip_headers CF-Connecting-IP
        }
      '';
      virtualHosts = lib.mapAttrs (name: vhost:
        if vhost.public then {
          # Same site block on both listeners: 443 for the LAN, publicPort for Cloudflare.
          serverAliases = [ "${name}:${port}" ];
          extraConfig = ''
            log
            ${handling vhost}
          '';
        } else {
          extraConfig = ''
            log

            @lan remote_ip ${lib.concatStringsSep " " cfg.lanSubnets}
            handle @lan {
              ${handling vhost}
            }
            handle {
              abort
            }
          '';
        }) cfg.virtualHosts;
    };
  };
}
