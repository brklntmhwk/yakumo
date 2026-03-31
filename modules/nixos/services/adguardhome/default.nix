# WIP
{
  config,
  lib,
  rootPath,
  yakumoMeta,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.adguardhome;
  meta = config.yakumo.services.metadata.adguardhome;
in
{
  options.yakumo.services.adguardhome = {
    enable = mkEnableOption "adguardhome";
  };

  config = mkIf cfg.enable (
    let
      inherit (meta)
        address
        domain
        port
        extraPorts
        ;
    in
    {
      services.adguardhome = {
        inherit port; # Default: 3000
        enable = true;
        # Specify this in `settings.dhcp.enabled` instead.
        # allowDHCP = settings.dhcp.enabled or false;
        host = address; # Default: '0.0.0.0'
        # Whether to allow changes made on the AdGuard Home web UI to persist
        # between service restarts.
        mutableSettings = false; # Default: true
        openFirewall = false; # Default: false
        extraArgs = [ ];
        # https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
        settings = {
          # Maximum number of failed login attempts before getting locked out.
          auth_attempts = 5;
          # The duration of blocking period in minutes.
          block_auth_min = 15;
          # Built-in DHCP server.
          # https://github.com/AdguardTeam/AdGuardHome/wiki/DHCP
          dhcp = {
            enabled = false;
          };
          dns = {
            # If true, anonymize clients' IP addresses in logs and stats.
            anonymize_client_ip = true;
            bind_hosts = [
              address
            ];
            port = extraPorts.dns;
            # Whether to turn on the DNS cache globally.
            cache_enabled = true;
            # Whether to allow info from the system hosts file to be used
            # to resolve queries.
            hostsfile_enabled = true;
            # The configuration for cache poisoning attacks protection.
            pending_requests = {
              # If true, AdGuard Home tracks simultaneous identical requests
              # and performs a single lookup for them.
              enabled = true;
            };
            # Specify how many queries per second AdGuard Home should handle.
            # Anything above this is silently dropped.
            # Safe to disable if DNS server is not available from the internet.
            ratelimit = 300; # Default: 20 (0 disables this).
            # Options:
            # - 'load_balance': Queries are sent to each upstream server one-by-one.
            # AdGuard Home uses a weighted random algorithm to select servers with
            # the lowest number of failed lookups and the lowest average lookup time.
            # - 'parallel': Parallel queries to all configured upstream servers
            # to speed up resolving.
            # - 'fastest_addr': It finds an IP address with the lowest latency
            # and returns this IP address in DNS response.
            upstream_mode = "load_balance";
            # List of upstream DNS servers.
            upstream_dns = [
              "https://dns.cloudflare.com/dns-query"
              "https://dns.mullvad.net/dns-query"
              "https://dns10.quad9.net/dns-query"
            ];
            # List of DNS servers used for initial hostname resolution in case
            # an upstream server name is a hostname.
            bootstrap_dns = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            # List of fallback DNS servers used when upstream DNS servers are not responding.
            fallback_dns = [ ];
            # Set DNSSEC (DNS Security Extensions) flag in the outgoing DNS requests
            # and check the result.
            enable_dnssec = true;
          };
          filters = [
            {
              enabled = true;
              id = 1;
              name = "AdGuard DNS filter";
              url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            }
            {
              enabled = true;
              id = 2;
              name = "AdAway Default Blocklist";
              url = "https://adaway.org/hosts.txt";
            }
            {
              enabled = true;
              id = 3;
              name = "OISD (Big)";
              url = "https://big.oisd.nl";
            }
          ];
          filtering = {
            # Specify how to block DNS requests.
            # Options:
            # - 'default': Respond with zero IP address (0.0.0.0 for A; :: for AAAA)
            # when blocked by Adblock-style rule; respond with the IP address
            # specified in the rule when blocked by /etc/hosts-style rule.
            # - 'custom_ip': Respond with a manually set IP address of an appropriate
            # family, which are specified in blocking_ipv4 and blocking_ipv6 properties.
            # - 'null_ip': Respond with zero IP address (0.0.0.0 for A; :: for AAAA).
            # - 'nxdomain': Respond with NXDOMAIN code.
            # - 'refused': Respond with REFUSED code.
            blocking_mode = "default";
            # Whether any kind of filtering and protection should be performed.
            protection_enabled = true;
            # Whether filtering of DNS requests based on rule lists should be performed.
            filtering_enabled = true;
            safe_search = {
              enabled = true;
            };
            # List of legacy DNS rewrites, where `domain` is the domain or wildcard
            # you want to be rewritten and `answer` is IP address, CNAME record,
            # `A` or `AAAA` special values.
            rewrites = [
              {
                enabled = true;
                domain = "*.${yakumoMeta.network.internal_domain}";
                answer = "";
              }
            ];
          };
          http = {
            # `address` will automatically be set to `${cfg.host}:${toString cfg.port}`.
          };
          language = "en";
          querylog = {
            enabled = true;
            interval = "24h";
          };
          statistics = {
            enabled = true;
            interval = "24h";
          };
          theme = "auto"; # Options: 'dark', 'light'
          # HTTPS/DoH/DoQ/DoT settings.
          tls =
            let
              acmeCertsDir = config.security.acme.certs.${domain}.directory;
            in
            {
              enabled = true;
              # Whether to force HTTP-to-HTTPS redirect.
              force_https = false; # A reverse proxy (e.g., Caddy) handles this.
              server_name = address;
              # Filesystem path to a PEM certificate.
              certificate_path = "${acmeCertsDir}/fullchain.pem";
              # Filesystem path to a PEM private key.
              private_key_path = "${acmeCertsDir}/key.pem";
              # The DNSCrypt port.
              port_dnscrypt = 0; # 0 disables this.
              # The HTTPS port. Used for both web UI and DNS-over-HTTPS.
              port_https = 0; # 0 disables this.
              # The DNS-over-TLS port.
              port_dns_over_tls = extraPorts.tls;
              # The DNS-over-QUIC port.
              port_dns_over_quic = extraPorts.tls;
              # Whether to enable strict SNI (Server Name Indication) check.
              # If true, reject connections if the client uses server name (in SNI)
              # that doesn't match the one in the certificate.
              strict_sni_check = false;
            };
          # Web users. If set to an empty list, authentication will be disabled.
          users = [
            {
              name = "admin";
              # Specify BCrypt-encrypted password.
              password = config.sops.secrets."adguardhome/admin_passwd".path;
            }
          ];
          # Web session TTL (Time To Live) in hours.
          # Web users will stay signed in for this hours long.
          web_session_ttl = 720; # 3 days
        };
      };

      networking.firewall = {
        # Open DNS ports.
        # The upstream module option `openFirewall` doesn't handle this.
        allowedTCPPorts = [ extraPorts.dns ];
        allowedUDPPorts = [ extraPorts.dns ];
      };

      yakumo =
        let
          yosugaCfg = config.yakumo.system.persistence.yosuga;
        in
        mkMerge [
          {
            services.metadata.adguardhome.reverseProxy = {
              caddyIntegration = {
                enable = true;
                acme.enable = true;
              };
            };
          }
          (mkIf yosugaCfg.enable {
            system.persistence.yosuga = {
              directories = [
                {
                  path = "/var/lib/private/AdGuardHome";
                  mode = "0700";
                }
              ];
            };
          })
        ];

      sops.secrets = {
        "adguardhome/admin_passwd" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
      };
    }
  );
}
