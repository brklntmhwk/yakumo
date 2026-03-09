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
  srvMetadata = config.yakumo.services.metadata.influxdb;
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
        http-bind-address = srvMetadata.bindAddress;
      };
    };

    services.caddy.virtualHosts = {
      "${srvMetadata.domain}" = {
        useACMEHost = "yakumo.net";
        extraConfig = ''
          reverse_proxy ${srvMetadata.bindAddress}
        '';
      };
    };
  };
}
