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
  cfg = config.yakumo.services.telegraf;
in
{
  options.yakumo.services.telegraf = {
    enable = mkEnableOption "telegraf";
  };

  config = mkIf cfg.enable {
    services.telegraf = {
      enable = true;
      environmentFiles = [ ];
      extraConfig = {
        inputs = {
          statsd = {
            delete_timings = true;
            service_address = ":8125";
          };
        };
        outputs = {
          influxdb = {
            database = "telegraf";
            urls = [
              "http://localhost:8086"
            ];
          };
        };
      };
    };
  };
}
