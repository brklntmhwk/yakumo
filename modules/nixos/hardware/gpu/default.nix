{
  config,
  lib,
  ...
}:

let
  inherit (lib) any hasPrefix mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (any (mod: hasPrefix "gpu" mod) hardwareMods) {
    hardware.graphics = {
      enable = true;
    };
  };
}
