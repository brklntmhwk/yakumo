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
  options.yakumo.desktop.apps.media = {
    # 'yakumo.desktop.apps.media.*' modules look up this.
    modules = mkOption {
      type = types.listOf (types.enum mediaMods);
      default = [ ];
      description = "List of desktop media modules to enable.";
      example = [
        "music"
        "video/davinci-resolve"
      ];
    };
  };
}
