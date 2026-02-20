# WIP
{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.syncthing;
in
{
  options.yakumo.services.syncthing = {
    enable = mkEnableOption "syncthing";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.syncthing = {
        enable = true;
      };
    }
  ]);
}
