{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.yakumo.system.nix;
in
{
  options.yakumo.system.nix = {
    enableFlake = mkEnableOption "Nix Flakes";
  };

  config = mkMerge [
    (mkIf cfg.enableFlake {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    })
  ];
}
