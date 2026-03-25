{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) elem mkIf;
  mediaMods = config.yakumo.tools.media.modules;
in
{
  config = mkIf (elem "video/davinci-resolve" mediaMods) {
    yakumo.user.packages = builtins.attrValues { inherit (pkgs) davinci-resolve; };
  };
}
