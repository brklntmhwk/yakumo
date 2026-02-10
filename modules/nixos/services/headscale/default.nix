{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.headscale;
in {
  options.yakumo.services.headscale = { enable = mkEnableOption "headscale"; };

  config =
    mkIf cfg.enable (mkMerge [{ services.headscale = { enable = true; }; }]);
}
