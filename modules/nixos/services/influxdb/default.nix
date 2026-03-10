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
  cfg = config.yakumo.services.influxdb;
  meta = config.yakumo.services.metadata.influxdb;
in
{
  options.yakumo.services.influxdb = {
    enable = mkEnableOption "influxdb";
  };

  config = mkIf cfg.enable {
    services.influxdb2 = {
      enable = true;
      provision = {
        enable = true;
        initialSetup = {
          username = "admin"; # Default: 'admin'
          bucket = "default";
          organization = "default";
          passwordFile = config.sops.secrets.influxdb_passwd.path;
          tokenFile = config.sops.secrets.influxdb_token.path;
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
            passwordFile = config.sops.secrets.login_password_otogaki.path;
            present = true; # Default: true
          };
        };
      };
      settings = {
        reporting-disabled = true;
        http-bind-address = meta.bindAddress;
      };
    };

    yakumo.services.metadata.influxdb.reverseProxy = {
      caddyIntegration.enable = true;
    };
  };
}
