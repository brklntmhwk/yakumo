{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.yakumo.system.networking.wifi;
  netManager = config.yakumo.system.networking.manager;
in {
  options.yakumo.system.networking.wifi = {
    enable = mkEnableOption "Wifi support";
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (netManager == "networkmanager") {
      networking = {
        networkmanager = {
          # Prefer iwd(iNet wireless daemon) over wpa_supplicant as backend.
          wifi.backend = "iwd";
        };
        wireless.iwd = {
          enable = true;
          settings = { General = { EnableNetworkConfiguration = true; }; };
        };
      };
    })
    (mkIf (netManager == "networkd") (let
      inherit (builtins) attrValues map;
      inherit (lib) genAttrs;
      interfaces = config.networking.wireless.interfaces;
      configDir = "/etc/wpa_supplicant.d";
    in {
      environment.systemPackages = attrValues {
        inherit (pkgs) wpa_supplicant; # wpa_cli & wpa_gui
      };

      # Use `networking.supplicant.<name>.*` instead of `networking.wireless.*`
      # preferring per-interface definition.
      networking.supplicant = genAttrs interfaces (interface: {
        userControlled = {
          enable = true;
          group = "users"; # Created in `yakumo.user.group`.
        };
        configFile = {
          path = "${configDir}/${interface}.conf";
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

      systemd.tmpfiles.rules = [
        "d ${configDir} 700 root root - -"
      ]
      # # e.g., `[ "f /etc/wpa_supplicant.d/wlp111s0.conf 700 root root - -" ... ]`
        ++ (map
          (interface: "f ${configDir}/${interface}.conf 700 root root - -")
          interfaces);

      # Prevent `systemd-networkd-wait-online` from waiting for all network interfaces
      # to be fully "up".
      # Without these settings, this service will wait until timeout if a Wi-Fi
      # network is out of range, wrong, or slow to associate.
      systemd.network.wait-online.ignoredInterfaces = interfaces;
      boot.initrd.systemd.network.wait-online.ignoredInterfaces = interfaces;
    }))
  ]);
}
