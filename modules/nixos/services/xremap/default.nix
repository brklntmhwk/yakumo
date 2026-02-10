{ inputs, config, options, lib, pkgs, murakumo, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption;
  inherit (murakumo.configs) mkInherit;
  cfg = config.yakumo.services.xremap;
  compositorsCfg = config.yakumo.desktop.compositors;
  upstream = options.services.xremap;
in {
  imports = [ inputs.xremap.nixosModules.default ];

  options.yakumo.services.xremap = {
    enable = mkEnableOption "Xremap key remapping service";
    # Hereafter, selectively inherit the upstream module options.
    # For the exhaustive list of the module options, see:
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    config =
      mkInherit upstream.config; # Prefer Nix-representable format over YAML.
    deviceName = mkInherit upstream.deviceName;
    deviceNames = mkInherit upstream.deviceNames;
    debug = mkInherit upstream.debug;
    extraArgs = mkInherit upstream.extraArgs;
    mouse = mkInherit upstream.mouse;
    package = mkInherit upstream.package;
    serviceMode = mkInherit upstream.serviceMode;
    userId = mkInherit upstream.userId;
    userName = mkInherit upstream.userName;
    watch = mkInherit upstream.watch;

    # Drop those 'with' prefixed options (e.g., 'withHypr') because
    # this custom module takes care of them instead.
  };

  config = mkIf cfg.enable {
    services.xremap = mkMerge [
      {
        enable = true;
        config = cfg.config;
        deviceName = cfg.deviceName;
        deviceNames = cfg.deviceNames;
        debug = cfg.debug;
        extraArgs = cfg.extraArgs;
        mouse = cfg.mouse;
        package = cfg.package;
        serviceMode = cfg.serviceMode;
        userId = cfg.userId;
        userName = cfg.userName;
        watch = cfg.watch;
      }
      # Add conditionals for DE or WM(compositor) specific integrations here.
      (mkIf (compositorsCfg.hyprland.enable) { withHypr = true; })
      (mkIf (compositorsCfg.niri.enable) { withNiri = true; })
    ];
  };
}
