# WIP
{
  config,
  lib,
  murakumo,
  rootMeta,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.services.calibre-server;
  meta = config.yakumo.services.metadata.calibre-server;
in
{
  options.yakumo.services.calibre-server = {
    enable = mkEnableOption "calibre-server";
  };

  config = mkIf cfg.enable {
    assertions =
      let
        inherit (murakumo.assertions) assertServiceUp;
      in
      [
        (assertServiceUp "calibre-server" rootMeta.allServices)
      ];

    services.calibre-server = {
      inherit (meta)
        port # Default: 8080
        ;
      enable = true;
      group = "calibre-server"; # Default: 'calibre-server'
      user = "calibre-server"; # Default: 'calibre-server'
      host = meta.address; # Default: '0.0.0.0'
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

    yakumo.services.metadata.calibre-server.reverseProxy = {
      caddyIntegration.enable = true;
    };
  };
}
