{ config, lib, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) any hasPrefix mkIf mkOption types;
  mediaMods = config.yakumo.desktop.apps.media.modules;
in {
  config = mkIf (any (mod: hasPrefix "music" mod) mediaMods) {
    yakumo.user.packages = attrValues {
      inherit (pkgs)
        mpv # Classic media player based on MPlayer and mplayer2
        mpvc # Music player interface to CLI/TUI using MPV
        playerctl # CLI for controlling media players
      ;
    };
    services.playerctld.enable = true; # Playerctl Daemon
  };
}
