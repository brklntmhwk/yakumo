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
in
{
  options.yakumo.services.mealie = {
    enable = mkEnableOption "mealie";
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
  };
}
