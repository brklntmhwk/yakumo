# WIP
{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.services.adguardhome;
  meta = config.yakumo.services.metadata.adguardhome;
in
{
  options.yakumo.services.adguardhome = {
    enable = mkEnableOption "adguardhome";
  };

  config = mkIf cfg.enable {
    services.adguardhome = {
      inherit (meta) port; # Default: 3000
      enable = true;
      # Specify this in `settings.dhcp.enabled` instead.
      # allowDHCP = settings.dhcp.enabled or false;
      host = meta.address; # Default: '0.0.0.0'
      # Whether to allow changes made on the AdGuard Home web UI to persist
      # between service restarts.
      mutableSettings = false; # Default: true
      openFirewall = false; # Default: false
      # https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
      settings = {
        # Built-in DHCP server.
        # https://github.com/AdguardTeam/AdGuardHome/wiki/DHCP
        dhcp = {
          enabled = false;
        };
        dns = {
          bind_hosts = [ ];
          port = meta.extraPorts.dns;
          ratelimit = 300;
          upstream_dns = [
            "https://dns.cloudflare.com/dns-query"
            "https://dns.mullvad.net/dns-query"
          ];
          bootstrap_dns = [ ];
          fallback_dns = [ ];
          dnssec_enabled = true;
        };
        filters = [
          {
            enabled = true;
            name = "AdGuard DNS filter";
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          }
          {
            enabled = true;
            name = "AdAway Default Blocklist";
            url = "https://adaway.org/hosts.txt";
          }
          {
            enabled = true;
            name = "OISD (Big)";
            url = "https://big.oisd.nl";
          }
        ];
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          safe_search.enabled = true;
          rewrites = [ ];
        };
        querylog = {
          enabled = true;
          interval = "24h";
        };
        statistics = {
          enabled = true;
          interval = "24h";
        };
        tls = {
          enabled = false;
        };
      };
      extraArgs = [ ];
    };

    yakumo.services.metadata.adguardhome.reverseProxy = {
      caddyIntegration.enable = true;
    };
  };
}
