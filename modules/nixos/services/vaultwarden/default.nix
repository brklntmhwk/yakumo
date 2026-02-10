{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkPackageOption types;
  cfg = config.yakumo.services.vaultwarden;
in {
  options.yakumo.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config =
    mkIf cfg.enable (mkMerge [{ services.vaultwarden = { enable = true; }; }]);
}
