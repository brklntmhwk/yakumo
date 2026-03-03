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
    mkOption
    types
    ;
  cfg = config.yakumo.services.adguardhome;
in
{
  options.yakumo.services.adguardhome = {
    enable = mkEnableOption "adguardhome";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable (
    let
      adguardCfg = config.services.adguardhome;
    in
    {
      services.adguardhome = {
        enable = true;
        # Specify this in `settings.dhcp.enabled` instead.
        # allowDHCP = settings.dhcp.enabled or false;
        host = "0.0.0.0"; # Default: '0.0.0.0'
        # Allow changes made on the AdGuard Home web UI to persist
        # between service restarts.
        mutableSettings = true; # Default: true
        openFirewall = true; # Default: false
        port = 3000; # Default: 3000
        settings = {
          dhcp.enabled = true;
        };
        extraArgs = [ ];
      };

      services.caddy.virtualHosts = {
        "${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy ${adguardCfg.host}:${builtins.toString adguardCfg.port}
          '';
        };
      };
    }
  );
}
