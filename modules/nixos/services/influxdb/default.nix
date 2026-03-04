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
    mkOption
    types
    ;
  cfg = config.yakumo.services.influxdb;
in
{
  options.yakumo.services.influxdb = {
    enable = mkEnableOption "influxdb";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
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
          passwordFile = config.sops.secrets.xxx.path;
          tokenFile = config.sops.secrets.xxx.path;
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
          otogaki = {
            passwordFile = config.sops.secrets.xxx.path;
            present = true; # Default: true
          };
        };
      };
      settings = {
        reporting-disabled = true;
        http-bind-address = "0.0.0.0:${toString 8086}";
      };
    };

    services.caddy.virtualHosts =
      let
        influxCfg = config.services.influxdb2;
      in
      {
        "${cfg.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${influxCfg.settings.http-bind-address}
          '';
        };
      };
  };
}
