{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkForce
    mkIf
    ;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "audio" hardwareMods) {
    # See https://wiki.nixos.org/wiki/PipeWire for more details.
    services.pulseaudio.enable = mkForce false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    security.rtkit.enable = true;
    yakumo.user = {
      extraGroups = [ "audio" ];
      packages = builtins.attrValues { inherit (pkgs) alsa-utils pavucontrol; };
    };
  };
}
