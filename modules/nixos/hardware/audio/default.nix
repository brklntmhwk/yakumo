{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    any
    hasPrefix
    mkForce
    mkIf
    ;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (any (mod: hasPrefix "audio" mod) hardwareMods) {
    # See https://wiki.nixos.org/wiki/PipeWire for more details.
    hardware.pulseaudio.enable = mkForce false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    security.rtkit.enable = true;
    yakumo.user = {
      extraGroups = [ "audio" ];
      packages = builtins.attrValues {
        inherit (pkgs)
          alsa-utils
          pavucontrol
          ;
      };
    };
  };
}
