# WIP
{
  config,
  lib,
  murakumo,
  rootMeta,
  rootPath,
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
      assertions =
        let
          inherit (murakumo.assertions) assertServiceUp;
        in
        [
          (assertServiceUp "adguardhome" rootMeta.allServices)
        ];

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
          # Persistent and runtime clients settings.
          clients = {
            # An array of explicitly configured clients.
            persistent = [ ];
            # Control runtime client data sources.
            runtime_sources = {
              # Request WHOIS information for clients with public IP addresses.
              whois = true;
              # Consider the operating system's ARP (Address Resolution Protocol) table.
              arp = true;
              # Perform rDNS lookups for client's address.
              rdns = true;
              # Check AdGuard Home's DHCP leases for client's address.
              dhcp = true;
              # Follow the operating system's hosts files.
              hosts = true;
            };
          };
          # Built-in DHCP server.
          # https://github.com/AdguardTeam/AdGuardHome/wiki/DHCP
          dhcp = {
            enabled = false;
            # Network interface name (eth0, en0, and so on).
            interface_name = "";
            # The domain name used for the hostnames of its clients, and by
            # AdGuard Home's DHCP server.
            local_domain_name = "lan";
            dhcpv4 = {
              gateway_ip = "";
              # Time to wait for an ICMP reply to detect an IP conflict, in milliseconds.
              # 0 means to disable it.
              icmp_timeout_msec = 1000;
              # Lease duration in seconds.
              # If set to 0, use the default duration: 24 hours.
              lease_duration = 86400;
              # The start of the leased IP address range.
              range_start = "";
              # The end of the leased IP address range.
              range_end = "";
              subnet_mask = "";
              # Custom DHCP options. For more details, see:
              # https://github.com/AdguardTeam/AdGuardHome/wiki/DHCP
              options = [ ];
            };
            dhcpv6 = {
              # The first IP address to be assigned to a client.
              range_start = "";
              # Same as the dhcpv4 above.
              lease_duration = 86400;
              # RA (Router Advertisement) is an ICMPv6 message (Type 134) used in IPv6
              # networks to automatically inform devices (nodes) about network prefixes,
              # default gateways, and configuration methods (SLAAC or DHCPv6).
              # Send RA packets forcing the clients to use SLAAC.
              ra_slaac_only = false;
              # Send RA packets allowing the clients to choose.
              ra_allow_slaac = false;
            };
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
            # DNS cache size in bytes.
            cache_size = 100000000; # 100MB
            # The minimum TTL override, in seconds.
            # If the TTL of a response from upstream is below this value, the TTL
            # is replaced with it. Must be less than or equal to `cache_ttl_max`.
            cache_ttl_min = 3600; # 1 hour
            # The maximum version of `cache_ttl_min`.
            cache_ttl_max = 86400; # 24 hours
            # Make AdGuard Home respond from the cache even when the entries are
            # expired and also try to refresh them.
            cache_optimistic = true;
            # TTL for answers from optimistic cache.
            cache_optimistic_answer_ttl = "30s";
            # The maximum amount of time that expired entries remain in the optimistic cache.
            cache_optimistic_max_age = "12h";
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
          # Filters a.k.a. Blocklists.
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
            # Specify how long the clients should cache a filtered response in seconds.
            blocked_response_ttl = 10;
            # Time interval in minutes for keeping cache records.
            cache_time = 30;
            # Whether filtering of DNS requests based on rule lists should be performed.
            filtering_enabled = true;
            # Time interval in hours for updating filters.
            filters_update_interval = 24;
            # Whether to enable network-wide parental controls, such as blocking adult
            # content, scheduling restrictions by day and time, etc.
            parental_enabled = false;
            parental_cache_size = 1048576; # Parental Control cache size, in bytes.
            # Whether any kind of filtering and protection should be performed.
            protection_enabled = true;
            # Timestamp until when the protection is disabled.
            protection_disabled_until = null;
            # Whether to enable filtering of DNS requests based on safebrowsing.
            # Safe Browsing is a protective feature that safeguards users from
            # malicious websites, phishing scams, malware distribution, etc.
            safebrowsing_enabled = true;
            safebrowsing_cache_size = 1048576; # Safe Browsing cache size, in bytes.
            # Safe Search is a feature that forces search engines to filter out
            # explicit, violent, or adult content from their search results.
            safe_search = {
              enabled = false; # Whether to enable it globally.
              bing = true;
              duckduckgo = true;
              ecosia = true;
              google = true;
              pixabay = true;
              yandex = true;
              youtube = true;
            };
            safesearch_cache_size = 1048576; # Safe Search cache size, in bytes.
            # List of legacy DNS rewrites, where `domain` is the domain or wildcard
            # you want to be rewritten and `answer` is IP address, CNAME record,
            # `A` or `AAAA` special values.
            # This tells Adguardhome, "If someone asks for this `domain`, give them
            # this `answer` immediately".
            rewrites = [
              {
                enabled = true;
                domain = "*.${rootMeta.network.internal_domain}";
                answer = address;
              }
            ];
          };
          http = {
            # `address` will automatically be set to:
            # `${config.services.adguardhome.host}:${toString config.services.adguardhome.port}`.
            # DNS-over-HTTPS.
            doh = {
              # List of HTTP route patterns for DoH requests.
              # Default routes are: `GET /dns-query`, `POST /dns-query`,
              # `GET /dns-query/{ClientID}`, `POST /dns-query/{ClientID}`.
              routes = "";
              # Whether to allow DoH queries via unencrypted HTTP (e.g., to use
              # with reverse proxies).
              insecure_enabled = false;
            };
            # Profiling HTTP handler configuration.
            # https://github.com/adguardteam/adguardhome/wiki/Configuration#pprof
            pprof = {
              enabled = false;
            };
            # Web session TTL (Time To Live).
            # Web users will stay signed in for this amount of time.
            session_ttl = "720h"; # 30 days
          };
          language = "en";
          log = {
            enabled = true;
            # Path to the log file.
            # Adguardhome writes to stdout if empty and syslog writes system log
            # (or eventlog on Windows).
            file = "";
            # Maximum number of old log files to retain.
            # 0 means, "Retain all old log files".
            max_backups = 0;
            # Maximum size of the log file before it gets rotated, in megabytes.
            max_size = 100;
            # Maximum number of days to retain old log files.
            max_age = 3;
            # Whether to enable GZIP compression of the log files.
            compress = false;
            # Whether to use the computer's local time for formatting the timestamps.
            local_time = false;
            # Whether to enable verbose debug output.
            verbose = false;
          };
          os = {
            # The name of the user group to switch to after the startup.
            group = "";
            # The name of the user to switch to after the startup.
            user = "";
            # Limit on the maximum number of open files for the server process
            # (on unixlike OSs).
            # If set to 0, use the system's default value.
            rlimit_nofile = 0;
          };
          querylog = {
            enabled = true;
            # Custom directory for storing query log files.
            dir_path = "";
            # Whether to write query logs to a file.
            file_enabled = true;
            # Time interval for query log files rotation in the human-readble duration
            # format.
            interval = "24h";
            # Number of entries kept in memory before they are flushed to disk.
            size_memory = 1000;
            # Whether to ignore hosts from the `ignored` list.
            ignored_enabled = true;
            # List of host names that should not be written to log.
            # For the AdBlock rule syntax, see:
            # https://adguard-dns.io/kb/general/dns-filtering-syntax/
            ignored = [ ];
          };
          statistics = {
            enabled = true;
            # Custom directory for storing statistics.
            dir_path = "";
            # Time interval for statistics in the human-readble duration format.
            interval = "24h";
            # Whether to ignore hosts from the `ignored` list.
            ignored_enabled = true;
            # List of host names that should not be written to log.
            ignored = [ ];
          };
          theme = "auto"; # Options: 'dark', 'light'
          # HTTPS/DoH/DoQ/DoT settings.
          tls =
            let
              acmeCertsDir = config.security.acme.certs.${domain}.directory;
            in
            {
              enabled = true;
              # If set, it's used to:
              # - detect ClientIDs by using the ServerName field of ClientHello messages
              # - respond to Discovery of Designated Resolvers (DDR) queries
              # - perform additional connection validations
              # If not specified, the above-mentioned features are disabled.
              server_name = address;
              # The path to the DNSCrypt configuration file.
              # Must be set if `port_dnscrypt` is not 0.
              dnscrypt_config_file = "";
              # Whether to force HTTP-to-HTTPS redirect.
              force_https = false; # A reverse proxy (e.g., Caddy) handles this.
              # Filesystem path to a PEM certificate.
              certificate_path = "${acmeCertsDir}/fullchain.pem";
              # Filesystem path to a PEM private key.
              private_key_path = "${acmeCertsDir}/key.pem";
              # If set, this array of strings allows overriding the default set of
              # TLS cipher suites to use.
              # For the valid strings, see:
              # https://pkg.go.dev/crypto/tls#pkg-constants
              override_tls_ciphers = [ ];
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
        };
      };

      networking.firewall =
        let
          inherit (builtins) attrValues;
        in
        {
          # Open DNS ports.
          # The upstream module option `openFirewall` doesn't handle this.
          allowedTCPPorts = attrValues {
            inherit (extraPorts) dns tls;
          };
          allowedUDPPorts = attrValues {
            inherit (extraPorts) dns tls;
          };
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
