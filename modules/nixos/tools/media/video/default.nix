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
  inherit (murakumo.platforms) isLinux;
  mediaMods = config.yakumo.tools.media.modules;
in
{
  config = mkIf (anyHasPrefix "video" mediaMods && isLinux) {
    yakumo.user.packages = attrValues {
      inherit (pkgs)
        mpv # Classic media player based on MPlayer and mplayer2
        ;
    };
  };
}
