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
  mediaMods = getDirNamesRecursive ./.;
in
{
  options.yakumo.desktop.media = {
    # 'yakumo.desktop.media.*' modules look up this.
    modules = mkOption {
      type = types.listOf (types.enum mediaMods);
      default = [ ];
      description = "List of desktop media modules to enable.";
    };
  };
}
