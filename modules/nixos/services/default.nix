{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkOption types;
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
      adguardhome = {
        domain = "adguard.yakumo.local";
        address = "127.0.0.1";
        port = 3000;
      };
      anki-sync-server = {
        domain = "anki.yakumo.local";
        address = "127.0.0.1";
        port = 8384;
      };
      calibre-server = {
        domain = "calibre.yakumo.local";
        address = "127.0.0.1";
        port = 8080;
      };
      calibre-web = {
        domain = "books.yakumo.local";
        address = "127.0.0.1";
        port = 8083;
      };
      forgejo = {
        domain = "git.yakumo.local";
        address = "127.0.0.1";
        port = 3001;
      };
      garage = {
        domain = "s3.yakumo.local";
        address = "127.0.0.1";
        port = 3900;
      };
      grafana = {
        domain = "grafana.yakumo.local";
        address = "127.0.0.1";
        port = 3002;
      };
      headscale = {
        domain = "headscale.yakumo.local";
        address = "127.0.0.1";
        port = 8081;
      };
      home-assistant = {
        domain = "hass.yakumo.local";
        address = "127.0.0.1";
        port = 8123;
      };
      immich = {
        domain = "media.yakumo.local";
        address = "127.0.0.1";
        port = 2283;
      };
      influxdb = {
        domain = "influx.yakumo.local";
        address = "127.0.0.1";
        port = 8086;
      };
      kanidm = {
        domain = "adguard.yakumo.local";
        address = "127.0.0.1";
        port = 8443;
      };
      mealie = {
        domain = "recipes.yakumo.local";
        address = "127.0.0.1";
        port = 9000;
      };
      mosquitto = {
        domain = "mqtt.yakumo.local";
        address = "127.0.0.1";
        port = 1883;
      };
      nfty-sh = {
        domain = "ntfy.yakumo.local";
        address = "127.0.0.1";
        port = 2586;
      };
      owntracks = {
        domain = "owntracks.yakumo.local";
        address = "127.0.0.1";
        port = 8085;
      };
      paperless-ngx = {
        domain = "paperless.yakumo.local";
        address = "127.0.0.1";
        port = 28981;
      };
      postgresql = {
        domain = "db.yakumo.local";
        address = "127.0.0.1";
        port = 5432;
      };
      shiori = {
        domain = "bookmarks.yakumo.local";
        address = "127.0.0.1";
        port = 8082;
      };
      stalwart-mail = {
        domain = "mail.yakumo.local";
        address = "127.0.0.1";
        port = 8084;
      };
      syncthing = {
        domain = "sync.yakumo.local";
        address = "127.0.0.1";
        port = 22067;
      };
      tailscale = {
        domain = "tailscale.yakumo.local";
        address = "127.0.0.1";
        port = 41641;
      };
      vaultwarden = {
        domain = "vault.yakumo.local";
        address = "127.0.0.1";
        port = 8222;
      };
    };
  };
}
