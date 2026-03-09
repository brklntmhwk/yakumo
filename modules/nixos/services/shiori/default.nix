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
  cfg = config.yakumo.services.shiori;
  srvMetadata = config.yakumo.services.metadata.shiori;
in
{
  options.yakumo.services.shiori = {
    enable = mkEnableOption "shiori";
  };

  config = mkIf cfg.enable {
    services.shiori = {
      inherit (srvMetadata)
        # If empty, Shiori listens on all interfaces.
        address # Default: ''
        port # Default: 8080
        ;
      enable = true;
      # Shiori can use MySQL or PostgreSQL.
      databaseUrl = "postgres:///shiori?host=/run/postgresql";
      environmentFile = config.sops.secrets.xxx.path; # Default: null
      webRoot = "/"; # Default: '/'
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
