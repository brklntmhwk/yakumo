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
in
{
  options.yakumo.services.shiori = {
    enable = mkEnableOption "shiori";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.shiori = {
        enable = true;
        address = "";
        # Shiori can use MySQL or PostgreSQL.
        databaseUrl = "postgres:///shiori?host=/run/postgresql";
        environmentFile = "/path/to/environmentFile";
        port = 8080; # Default: 8080
        webRoot = "/"; # Default: '/'
      };
    }
  ]);
}
