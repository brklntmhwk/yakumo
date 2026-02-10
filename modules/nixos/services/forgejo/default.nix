{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.forgejo;
in {
  options.yakumo.services.forgejo = { enable = mkEnableOption "forgejo"; };

  config =
    mkIf cfg.enable (mkMerge [{ services.forgejo = { enable = true; }; }]);
}
