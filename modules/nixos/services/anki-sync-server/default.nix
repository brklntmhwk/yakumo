{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.anki-sync-server;
in {
  options.yakumo.services.anki-sync-server = {
    enable = mkEnableOption "anki-sync-server";
  };

  config = mkIf cfg.enable
    (mkMerge [{ services.anki-sync-server = { enable = true; }; }]);
}
