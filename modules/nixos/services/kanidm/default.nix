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
  cfg = config.yakumo.services.kanidm;
in
{
  options.yakumo.services.kanidm = {
    enable = mkEnableOption "kanidm";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.kanidm = {
        enable = true;
      };
    }
  ]);
}
