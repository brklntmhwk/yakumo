{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.grafana;
in {
  options.yakumo.services.grafana = { enable = mkEnableOption "grafana"; };

  config =
    mkIf cfg.enable (mkMerge [{ services.grafana = { enable = true; }; }]);
}
