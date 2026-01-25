{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.networking.wifi;
  interfaces = config.networking.wireless.interfaces;
in
{
  options.yakumo.networking.wifi = {
    enable = mkEnableOption "Wifi support";
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) attrValues;
      inherit (lib) genAttrs;
    in
    {
      # Use `networking.supplicant.<name>.*` instead of `networking.wireless.*`
      # preferring per-interface definition.
      networking.supplicant = genAttrs interfaces (interface: {
        userControlled = {
          enable = true;
          group = "yakumo"; # Created in `yakumo.user.group`.
        };
        configFile = {
          path = "/etc/wpa_supplicant.d/${interface}.conf";
          writable = true;
        };
        # Explicitly allow overwriting the configuration.
        # "ap_scan": 1 auto-scanning, 0
        # Disable Wi-Fi Direct/P2P(Peer-to-Peer) for stability.
        # "Opportunistic Key Caching" helps speed up roaming between access points.
        extraConf = ''
          update_config=1
          ap_scan=1
          p2p_disabled=1
          okc=1
        '';
      });
      environment.systemPackages = attrValues {
        inherit (pkgs) wpa_supplicant; # wpa_cli & wpa_gui
      };
    }
  );
}
