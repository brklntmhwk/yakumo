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
    mkMerge
    ;
  cfg = config.yakumo.services.calibre-web;
  meta = config.yakumo.services.metadata.calibre-web;
in
{
  options.yakumo.services.calibre-web = {
    enable = mkEnableOption "calibre-web";
  };

  config = mkIf cfg.enable {
    assertions =
      let
        inherit (murakumo.assertions) assertServiceUp;
      in
      [
        (assertServiceUp "calibre-web" rootMeta.allServices)
      ];

    services.calibre-web = {
      enable = true;
      group = "calibre-web"; # Default: 'calibre-web'
      user = "calibre-web"; # Default: 'calibre-web'
      # Note that this will be concatenated with '/var/lib/' if not specified
      # as an absolute path (e.g., '/path/to/calibre-web-data').
      dataDir = "calibre-web";
      openFirewall = false; # Default: false
      listen = {
        inherit (meta) port; # Default: 8083
        ip = meta.address; # Default: '::1'
      };
      options = {
        # Path to Calibre library.
        calibreLibrary = null; # Default: null
        enableBookConversion = true; # Default: false
        enableBookUploading = true; # Default: false
        enableKepubify = false; # Default: false
        reverseProxyAuth = {
          enable = true; # Default: false
          header = ""; # Default: ''
        };
      };
    };

    yakumo =
      let
        yosugaCfg = config.yakumo.system.persistence.yosuga;
      in
      mkMerge [
        {
          services.metadata.calibre-web.reverseProxy = {
            caddyIntegration.enable = true;
          };
        }
        (mkIf yosugaCfg.enable {
          system.persistence.yosuga = {
            directories = [
              {
                inherit (config.services.calibre-web) group user;
                path = "/var/lib/calibre-web";
                mode = "0700";
              }
            ];
          };
        })
      ];
  };
}
