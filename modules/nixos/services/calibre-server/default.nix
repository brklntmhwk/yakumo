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
  cfg = config.yakumo.services.calibre;
in
{
  options.yakumo.services.calibre-server = {
    enable = mkEnableOption "calibre-server";
  };

  config = mkIf cfg.enable {
    services.calibre-server = {
      enable = true;
      group = "calibre-server"; # Default: 'calibre-server'
      user = "calibre-server"; # Default: 'calibre-server'
      host = "0.0.0.0"; # Default: '0.0.0.0'
      port = 8080; # Default: 8080
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
  };
}
