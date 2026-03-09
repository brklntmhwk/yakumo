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
          description = "Port number.";
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
            config = mkOption {
              type = types.lines;
              default = ''
                reverse_proxy ${config.bindAddress}
              '';
              description = ''
                Lines of Caddyfile configuration.
                The default value is the common bare minimum configuration.
              '';
            };
            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = ''
                Additional lines of Caddyfile configuration appended to the file
                after `''${config.reverseProxy.caddyIntegration.config}`.
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
      nfty-sh = {
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
      calibre-server = {
        domain = "calibre.yakumo.local";
        address = "127.0.0.1";
        port = 8080;
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
      stalwart-mail = {
        domain = "mail.yakumo.local";
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
        proxiedServices = filterAttrs (
          _: meta: meta.reverseProxy.enable
        ) config.yakumo.services.metadata;
      in
      mapAttrs' (
        _: meta:
        nameValuePair meta.domain {
          # Specify a host of an existing Let's Encrypt certificate.
          # Useful when we use DNS challenges but Caddy doesn't support our DNS provider.
          useACMEHost = "yakumo.net";
          extraConfig = ''
            ${meta.reverseProxy.config}
            ${meta.reverseProxy.extraConfig}
          '';
        }
      ) proxiedServices;
  };
}
