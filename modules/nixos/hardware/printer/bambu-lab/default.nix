{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) elem mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "printer/bambu-lab" hardwareMods) {
    yakumo.user.packages = builtins.attrValues { inherit (pkgs) bambu-studio; };
  };
}
