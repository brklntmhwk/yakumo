{ config, lib, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) any hasPrefix mkIf mkOption types;
  mediaMods = config.yakumo.desktop.apps.media.modules;
in {
  config = mkIf (any (mod: hasPrefix "video" mod) mediaMods) {
    yakumo.user.packages = attrValues {
      inherit (pkgs) mpv # Classic media player based on MPlayer and mplayer2
      ;
    };
  };
}
