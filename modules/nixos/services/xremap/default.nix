{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkMerge;
  cfg = config.services.xremap;
  compositorsCfg = config.yakumo.desktop.compositors;
in
{
  imports = [ inputs.xremap.nixosModules.default ];

  config = mkIf cfg.enable {
    services.xremap = mkMerge [
      # Add conditionals for DE or WM(compositor) specific integrations here.
      (mkIf (compositorsCfg.hyprland.enable) { withHypr = true; })
      (mkIf (compositorsCfg.niri.enable) { withNiri = true; })
    ];
  };
}
