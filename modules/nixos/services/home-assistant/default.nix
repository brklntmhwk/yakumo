{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.services.home-assistant;
in
{
  options.yakumo.services.home-assistant = {
    enable = mkEnableOption "home-assistant";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.home-assistant = {
        enable = true;
      };
    }
  ]);
}
