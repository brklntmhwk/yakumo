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
  systemCfg = config.yakumo.system;
in
{
  options.yakumo.services.calibre-web = {
    enable = mkEnableOption "calibre-web";
  };

  config = mkIf cfg.enable {
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
  };
}
