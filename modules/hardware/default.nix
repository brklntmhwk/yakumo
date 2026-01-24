{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;
  inherit (murakumo.util) getDirNamesRecursive;
  hardwareMods = getDirNamesRecursive ./.;
in
{
  options.yakumo.hardware = {
    # 'yakumo.hardware.*' modules look up this.
    modules = mkOption {
      type = types.listOf (types.enum hardwareMods);
      default = [ ];
      description = "List of hardware modules to enable.";
    };
  };
}
