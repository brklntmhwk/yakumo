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
  cfg = config.yakumo.services.mealie;
in
{
  options.yakumo.services.mealie = {
    enable = mkEnableOption "mealie";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable {
    services.mealie = {
      enable = true;
      credentialsFile = "/run/secrets/mealie-credentials.env";
      # Setup local PostgreSQL DB server for Mealie.
      database.createLocally = true; # Default: false
      listenAddress = "0.0.0.0"; # Default: '0.0.0.0'
      port = 9000; # Default: 9000
      settings = {
        ALLOW_SIGNUP = "false";
      };
      extraOptions = [ ];
    };

    services.caddy.virtualHosts =
      let
        inherit (mealieCfg) listenAddress port;
        mealieCfg = config.services.mealie;
      in
      {
        "${cfg.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${listenAddress}:${builtins.toString port}
          '';
        };
      };
  };
}
