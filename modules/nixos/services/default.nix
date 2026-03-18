{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mkEnableOption
    mkOption
    nameValuePair
    types
    ;
  serviceSubmodule =
    { config, ... }:
    {
      options = {
        domain = mkOption {
          type = types.str;
          description = "Service domain.";
        };
        address = mkOption {
          type = types.str;
          description = "IP address.";
        };
        port = mkOption {
          type = types.port;
          description = "Primary port number (usually for the web UI or HTTP API).";
        };
        extraPorts = mkOption {
          type = types.attrsOf types.port;
          default = { };
          description = "Additional ports for services with multiple listeners.";
        };
        bindAddress = mkOption {
          type = types.str;
          default = "${config.address}:${builtins.toString config.port}";
          readOnly = true;
          description = "Bind address.";
        };
        reverseProxy = {
          caddyIntegration = {
            enable = mkEnableOption "reverse proxy integaration feat. Caddy";
            extraConfig = mkOption {
              type = types.lines;
              default = ''
                reverse_proxy ${config.bindAddress}
              '';
              description = ''
                Additional lines of Caddyfile configuration appended to the file.
                The default value is the common bare minimum configuration.
              '';
            };
          };
        };
      };
    };
in
{
  options.yakumo.services = {
    metadata = mkOption {
      type = types.attrsOf (types.submodule serviceSubmodule);
      readOnly = true;
      description = "Service metadata to look up among service modules.";
    };
  };

  config = {
    yakumo.services.metadata = {
      # Sorted by port number.
      rustic = {
        domain = "backup.yakumo.local";
        address = "127.0.0.1";
        # Use 0 as a placeholder if it doesn't bind to a port.
        # Rustic is typically a CLI tool, but if using rest-server it defaults to 8000.
        port = 0;
      };
      caddy = {
        domain = "proxy.yakumo.local";
        address = "127.0.0.1";
        port = 443;
      };
      samba = {
        domain = "smb.yakumo.local";
        address = "127.0.0.1";
        port = 445;
      };
      mosquitto = {
        domain = "mqtt.yakumo.local";
        address = "127.0.0.1";
        port = 1883;
      };
      immich = {
        domain = "media.yakumo.local";
        address = "127.0.0.1";
        port = 2283;
      };
      ntfy-sh = {
        domain = "ntfy.yakumo.local";
        address = "127.0.0.1";
        port = 2586;
      };
      adguardhome = {
        domain = "adguard.yakumo.local";
        address = "127.0.0.1";
        port = 3000;
      };
      forgejo = {
        domain = "git.yakumo.local";
        address = "127.0.0.1";
        port = 3001;
      };
      grafana = {
        domain = "grafana.yakumo.local";
        address = "127.0.0.1";
        port = 3002;
      };
      garage = {
        domain = "s3.yakumo.local";
        address = "127.0.0.1";
        port = 3900;
      };
      postgresql = {
        domain = "db.yakumo.local";
        address = "127.0.0.1";
        port = 5432;
      };
      stalwart-mail = {
        domain = "mail.yakumo.local";
        address = "127.0.0.1";
        port = 8080;
        extraPorts = {
          smtp = 25;
          submissions = 465;
          imaps = 993;
          sieve = 4190;
        };
      };
      headscale = {
        domain = "headscale.yakumo.local";
        address = "127.0.0.1";
        port = 8081;
      };
      shiori = {
        domain = "bookmarks.yakumo.local";
        address = "127.0.0.1";
        port = 8082;
      };
      calibre-web = {
        domain = "books.yakumo.local";
        address = "127.0.0.1";
        port = 8083;
      };
      calibre-server = {
        domain = "calibre.yakumo.local";
        address = "127.0.0.1";
        port = 8084;
      };
      owntracks = {
        domain = "owntracks.yakumo.local";
        address = "127.0.0.1";
        port = 8085;
      };
      influxdb = {
        domain = "influx.yakumo.local";
        address = "127.0.0.1";
        port = 8086;
      };
      home-assistant = {
        domain = "hass.yakumo.local";
        address = "127.0.0.1";
        port = 8123;
      };
      vaultwarden = {
        domain = "vault.yakumo.local";
        address = "127.0.0.1";
        port = 8222;
      };
      anki-sync-server = {
        domain = "anki.yakumo.local";
        address = "127.0.0.1";
        port = 8384;
      };
      kanidm = {
        domain = "idm.yakumo.local";
        address = "127.0.0.1";
        port = 8443;
      };
      mealie = {
        domain = "recipes.yakumo.local";
        address = "127.0.0.1";
        port = 9000;
      };
      telegraf = {
        domain = "telegraf.yakumo.local";
        address = "127.0.0.1";
        port = 9273; # Default Prometheus metric listener port.
      };
      syncthing = {
        domain = "sync.yakumo.local";
        address = "127.0.0.1";
        port = 22067;
      };
      paperless-ngx = {
        domain = "paperless.yakumo.local";
        address = "127.0.0.1";
        port = 28981;
      };
      tailscale = {
        domain = "tailscale.yakumo.local";
        address = "127.0.0.1";
        port = 41641;
      };
    };

    services.caddy.virtualHosts =
      let
        proxiedServices = filterAttrs (_: meta: meta.reverseProxy.enable) config.yakumo.services.metadata;
      in
      mapAttrs' (
        _: meta:
        nameValuePair meta.domain {
          # Specify a host of an existing Let's Encrypt certificate.
          # Useful when we use DNS challenges but Caddy doesn't support our DNS provider.
          useACMEHost = "yakumo.net";
          extraConfig = ''
            ${meta.reverseProxy.extraConfig}
          '';
        }
      ) proxiedServices;
  };
}
