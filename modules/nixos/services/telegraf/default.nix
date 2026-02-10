{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.telegraf;
in {
  options.yakumo.services.telegraf = { enable = mkEnableOption "telegraf"; };

  config =
    mkIf cfg.enable (mkMerge [{ services.telegraf = { enable = true; }; }]);
}
