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
in
{
  options.yakumo.services.influxdb = {
    enable = mkEnableOption "influxdb";
  };

  config = mkIf cfg.enable {
    services.influxdb = {
      enable = true;
      group = "influxdb"; # Default: 'influxdb'
      user = "influxdb"; # Default: 'influxdb'
      dataDir = "/var/db/influxdb";
      extraConfig = { };
    };
  };
}
