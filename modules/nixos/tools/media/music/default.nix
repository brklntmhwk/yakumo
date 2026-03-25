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
  config = mkIf (anyHasPrefix "music" mediaMods && isLinux) {
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
