{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.syncthing;
in {
  options.yakumo.services.syncthing = { enable = mkEnableOption "syncthing"; };

  config =
    mkIf cfg.enable (mkMerge [{ services.syncthing = { enable = true; }; }]);
}
