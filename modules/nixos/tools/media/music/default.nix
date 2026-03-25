{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) mkIf;
  inherit (murakumo.utils) anyHasPrefix;
  mediaMods = config.yakumo.tools.media.modules;
in
{
  config = mkIf (anyHasPrefix "music" mediaMods) {
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
