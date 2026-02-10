{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.mealie;
in {
  options.yakumo.services.mealie = { enable = mkEnableOption "mealie"; };

  config =
    mkIf cfg.enable (mkMerge [{ services.mealie = { enable = true; }; }]);
}
