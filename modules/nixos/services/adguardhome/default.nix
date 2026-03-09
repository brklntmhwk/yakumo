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
  meta = config.yakumo.services.metadata.adguardhome;
in
{
  options.yakumo.services.adguardhome = {
    enable = mkEnableOption "adguardhome";
  };

  config = mkIf cfg.enable {
    services.adguardhome = {
      inherit (meta) port; # Default: 3000
      enable = true;
      # Specify this in `settings.dhcp.enabled` instead.
      # allowDHCP = settings.dhcp.enabled or false;
      host = meta.address; # Default: '0.0.0.0'
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
      "${meta.domain}" = {
        useACMEHost = "yakumo.net";
        extraConfig = ''
          reverse_proxy ${meta.bindAddress}
        '';
      };
    };
  };
}
