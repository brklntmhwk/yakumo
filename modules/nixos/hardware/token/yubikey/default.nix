{
  config,
  pkgs,
  lib,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    elem
    mkIf
    ;
  inherit (murakumo.platforms) isLinux;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "token/yubikey" hardwareMods) {
    environment.systemPackages = attrValues {
      inherit (pkgs)
        yubikey-manager # The modern CLI tool (ykman)
        yubikey-personalization # The legacy tools
        ;
    };

    # Lets you know when Yubikey's waiting for skinship.
    programs.yubikey-touch-detector = {
      enable = true;
      libnotify = true; # Default: true
      unixSocket = true; # Default: true
    };

    services.udev.packages = attrValues { inherit (pkgs) yubikey-personalization; };
  };
}
