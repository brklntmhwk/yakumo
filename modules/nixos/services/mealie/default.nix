# WIP
{
  config,
  lib,
  flakeRoot,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.mealie;
  meta = config.yakumo.services.metadata.mealie;
in
{
  options.yakumo.services.mealie = {
    enable = mkEnableOption "mealie";
  };

  config = mkIf cfg.enable (
    let
      sopsCfg = config.yakumo.secrets.sops;
    in
    mkMerge [
      {
        services.mealie = {
          inherit (meta) port; # Default: 9000
          enable = true;
          # Setup local PostgreSQL DB server for Mealie.
          database.createLocally = true; # Default: false
          listenAddress = meta.address; # Default: '0.0.0.0'
          settings = {
            ALLOW_SIGNUP = "false";
          };
          extraOptions = [ ];
        };

        yakumo =
          let
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata.mealie.reverseProxy = {
                caddyIntegration.enable = true;
              };
            }
            (mkIf yosugaCfg.enable {
              system.persistence.yosuga = {
                directories = [
                  {
                    directory = "/var/lib/mealie";
                    user = "mealie";
                    group = "mealie";
                    mode = "0750";
                  }
                ];
              };
            })
          ];
      }
      (mkIf sopsCfg.enable {
        sops.secrets = {
          mealie_credentials = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
        };

        services.mealie = {
          credentialsFile = config.sops.secrets.mealie_credentials.path;
        };
      })
    ]
  );
}
