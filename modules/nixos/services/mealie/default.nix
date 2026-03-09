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
  cfg = config.yakumo.services.mealie;
  meta = config.yakumo.services.metadata.mealie;
in
{
  options.yakumo.services.mealie = {
    enable = mkEnableOption "mealie";
  };

  config = mkIf cfg.enable {
    services.mealie = {
      inherit (meta) port; # Default: 9000
      enable = true;
      credentialsFile = "/run/secrets/mealie-credentials.env";
      # Setup local PostgreSQL DB server for Mealie.
      database.createLocally = true; # Default: false
      listenAddress = meta.address; # Default: '0.0.0.0'
      settings = {
        ALLOW_SIGNUP = "false";
      };
      extraOptions = [ ];
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
