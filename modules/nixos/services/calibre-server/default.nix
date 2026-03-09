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
  cfg = config.yakumo.services.calibre-server;
  srvMetadata = config.yakumo.services.metadata.calibre-server;
in
{
  options.yakumo.services.calibre-server = {
    enable = mkEnableOption "calibre-server";
  };

  config = mkIf cfg.enable {
    services.calibre-server = {
      inherit (srvMetadata)
        address # Default: '0.0.0.0'
        port # Default: 8080
        ;
      enable = true;
      group = "calibre-server"; # Default: 'calibre-server'
      user = "calibre-server"; # Default: 'calibre-server'
      openFirewall = false; # Default: false
      extraFlags = [ ];
      libraries = [ ];
      auth = {
        enable = true; # Default: false
        mode = "auto"; # Default: 'auto' (Options: 'basic', 'digest')
        # Choose users DB file to use for authentication.
        # Ensure to initialize it before service startup.
        userDb = null; # Default: null
      };
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
