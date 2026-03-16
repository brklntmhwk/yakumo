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
  meta = config.yakumo.services.metadata.shiori;
in
{
  options.yakumo.services.shiori = {
    enable = mkEnableOption "shiori";
  };

  config = mkIf cfg.enable (
    let
      sopsCfg = config.yakumo.secrets.sops;
    in
    mkMerge [
      {
        services.shiori = {
          inherit (meta)
            # If empty, Shiori listens on all interfaces.
            address # Default: ''
            port # Default: 8080
            ;
          enable = true;
          # Shiori can use MySQL or PostgreSQL.
          databaseUrl = "postgres:///shiori?host=/run/postgresql";
          webRoot = "/"; # Default: '/'
        };

        yakumo.services.metadata.shiori.reverseProxy = {
          caddyIntegration.enable = true;
        };
      }
      (mkIf sopsCfg.enable {
        sops.secrets = {
          shiori_env = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
        };

        services.shiori = {
          environmentFile = config.sops.secrets.shiori_env.path; # Default: null
        };
      })
    ]
  );
}
