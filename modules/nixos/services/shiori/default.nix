# WIP
{
  config,
  lib,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.shiori;
  meta = config.yakumo.services.metadata.shiori;
in
{
  options.yakumo.services.shiori = {
    enable = mkEnableOption "shiori";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.shiori = {
        inherit (meta)
          # If empty, Shiori listens on all interfaces.
          address # Default: ''
          port # Default: 8080
          ;
        enable = true;
        environmentFile = config.sops.secrets."shiori/env_file".path; # Default: null
        # Shiori can use MySQL or PostgreSQL.
        databaseUrl = "postgres:///shiori?host=/run/postgresql";
        webRoot = "/"; # Default: '/'
      };

      yakumo.services.metadata.shiori.reverseProxy = {
        caddyIntegration.enable = true;
      };

      sops.secrets = {
        "shiori/env_file" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
      };
    }
  ]);
}
