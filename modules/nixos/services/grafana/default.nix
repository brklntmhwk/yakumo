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
    mkMerge
    ;
  cfg = config.yakumo.services.grafana;
in
{
  options.yakumo.services.grafana = {
    enable = mkEnableOption "grafana";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.grafana = {
        enable = true;
      };
    }
  ]);
}
