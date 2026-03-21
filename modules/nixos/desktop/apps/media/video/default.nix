{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    mkIf
    mkOption
    types
    ;
  inherit (murakumo.utils) anyHasPrefix;
  mediaMods = config.yakumo.desktop.apps.media.modules;
in
{
  config = mkIf (anyHasPrefix "video" mediaMods) {
    yakumo.user.packages = attrValues {
      inherit (pkgs)
        mpv # Classic media player based on MPlayer and mplayer2
        ;
    };
  };
}
