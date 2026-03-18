# WIP
{
  config,
  lib,
  flakeRoot,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.influxdb;
  meta = config.yakumo.services.metadata.influxdb;
in
{
  options.yakumo.services.influxdb = {
    enable = mkEnableOption "influxdb";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.influxdb2 = {
        enable = true;
        provision = {
          enable = true;
          initialSetup = {
            username = "admin"; # Default: 'admin'
            passwordFile = config.sops.secrets.influxdb_passwd.path;
            tokenFile = config.sops.secrets.influxdb_token.path;
            bucket = "default";
            organization = "default";
            # Set how long the bucket retains data (0 means infinite).
            retention = 0; # Default: 0
          };
          organizations = {
            machines = {
              description = "";
              present = true; # Default: true
              auths = { };
              buckets.telegraf = {
                description = "";
                present = true; # Default: true
                retention = 0; # Default: 0
              };
            };
          };
          users = {
            # TODO: Refactor this so this module doesn't know about the users.
            otogaki = {
              passwordFile = config.sops.secrets.login_passwd_otogaki.path;
              present = true; # Default: true
            };
          };
        };
        settings = {
          reporting-disabled = true;
          http-bind-address = meta.bindAddress;
        };
      };

      yakumo =
        let
          yosugaCfg = config.yakumo.system.persistence.yosuga;
        in
        mkMerge [
          {
            services.metadata.influxdb.reverseProxy = {
              caddyIntegration.enable = true;
            };
          }
          (mkIf yosugaCfg.enable {
            system.persistence.yosuga = {
              directories = [
                {
                  path = "/var/lib/influxdb2";
                  user = "influxdb2";
                  group = "influxdb2";
                  mode = "0700";
                }
              ];
            };
          })
        ];

      sops.secrets = {
        influxdb_passwd = {
          sopsFile = flakeRoot + "/secrets/default.yaml";
        };
        influxdb_token = {
          sopsFile = flakeRoot + "/secrets/default.yaml";
        };
      };
    }
  ]);
}
