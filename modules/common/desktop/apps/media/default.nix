{
  config,
  lib,
  murakumo,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (murakumo.utils) getDirNamesRecursive;
  commonMedia = getDirNamesRecursive ./.;
  cfg = config.yakumo.desktop.apps.media;
in
{
  options.yakumo.desktop.apps.media = {
    availableModules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
      # readOnly = true;
      description = "List of available media modules collected from all active platform layers.";
    };
    # 'yakumo.desktop.apps.media.*' modules look up this.
    modules = mkOption {
      type = types.listOf (types.enum cfg.availableModules);
      default = [ ];
      description = "List of desktop media modules to enable.";
      example = [
        "music"
        "video/davinci-resolve"
      ];
    };
  };

  config.yakumo.desktop.apps.media.availableModules = commonMedia;
}
