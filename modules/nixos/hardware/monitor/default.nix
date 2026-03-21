{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    ;
  inherit (murakumo.platforms) isx86_64;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "monitor" hardwareMods) (mkMerge [
    {
      yakumo.user.packages = builtins.attrValues {
        inherit (pkgs)
          brightnessctl # CLI tool to read and control device brightness.
          ;
      };
    }
    (mkIf isx86_64 {
      # https://discourse.nixos.org/t/brightness-control-of-external-monitors-with-ddcci-backlight/8639/18
      boot = {
        kernelModules = [
          "i2c-dev" # Allow tools like 'ddcutil' to talk to monitors.
          "ddcci_backlight" # Allow the kernel to expose monitors as backlights.
        ];
        # Add 'ddcci' and 'ddcci_backlight' modules.
        extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
      };
      # Useful for debugging of the kernel driver fails.
      environment.systemPackages = [ pkgs.ddcutil ];

      yakumo.user.extraGroups = [ "i2c" ];
    })
  ]);
}
