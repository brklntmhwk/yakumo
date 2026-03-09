# WIP
{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.services.adguardhome;
  srvMetadata = config.yakumo.services.metadata.adguardhome;
in
{
  options.yakumo.services.adguardhome = {
    enable = mkEnableOption "adguardhome";
  };

  config = mkIf cfg.enable {
    services.adguardhome = {
      inherit (srvMetadata) port; # Default: 3000
      enable = true;
      # Specify this in `settings.dhcp.enabled` instead.
      # allowDHCP = settings.dhcp.enabled or false;
      host = srvMetadata.address; # Default: '0.0.0.0'
      # Allow changes made on the AdGuard Home web UI to persist
      # between service restarts.
      mutableSettings = true; # Default: true
      openFirewall = true; # Default: false
      settings = {
        dhcp.enabled = true;
      };
      extraArgs = [ ];
    };

    services.caddy.virtualHosts = {
      "${srvMetadata.domain}" = {
        useACMEHost = "yakumo.net";
        extraConfig = ''
          reverse_proxy ${srvMetadata.bindAddress}
        '';
      };
    };
  };
}
