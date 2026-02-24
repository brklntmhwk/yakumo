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
    mkMerge
    ;
  cfg = config.yakumo.services.calibre;
  systemCfg = config.yakumo.system;
in
{
  options.yakumo.services.calibre = {
    enable = mkEnableOption "calibre";
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (systemCfg.role == "workstation") {
      services.calibre-web = {
        enable = true;
        group = "calibre-web"; # Default: 'calibre-web'
        user = "calibre-web"; # Default: 'calibre-web'
        # Note that this will be concatenated with '/var/lib/' if not specified
        # as an absolute path (e.g., '/path/to/calibre-web-data').
        dataDir = "calibre-web";
        openFirewall = false; # Default: false
        listen = {
          ip = "::1"; # Default: '::1'
          port = 8083; # Default: 8083
        };
        options = {
          # Path to Calibre library.
          calibreLibrary = null; # Default: null
          enableBookConversion = false; # Default: false
          enableBookUploading = false; # Default: false
          enableKepubify = false; # Default: false
          reverseProxyAuth = {
            enable = true; # Default: false
            header = ""; # Default: ''
          };
        };
      };
    })
    (mkIf (systemCfg.role == "server") {
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
    })
  ]);
}
