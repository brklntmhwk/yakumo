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
        # `update_config=1`: Explicitly allow overwriting the configuration.
        # `ap_scan`: "Access Point Scan"
        # - 1: Actively scan for broadcasted SSIDs.
        # - 0: Don't scan at all. Sit back and wait for the Kernel driver to trigger
        # the scan and select the Access Point.
        # - 2: Try to find hidden networks when `ap_scan=1` fails, or associate with
        # networks specifically by security policy rather than SSID broadcasting.
        # `p2p_disabled=1`: Disable Wi-Fi Direct/P2P(Peer-to-Peer) for stability.
        # `okc`: "Opportunistic Key Caching"
        # - 1: Help speed up roaming between access points.
        # - 0: Off.
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
