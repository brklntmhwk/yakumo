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
  cfg = config.yakumo.services.garage;
in
{
  options.yakumo.services.garage = {
    enable = mkEnableOption "garage";
  };

  config = mkIf cfg.enable (
    let
      sopsCfg = config.yakumo.secrets.sops;
    in
    mkMerge [
      {
        services.garage = {
          enable = true;
          extraEnvironment = { };
          logLevel = "info"; # Default: 'info' (Options: 'debug', 'error', 'trace', 'warn')
          settings = { };
        };
      }
      (mkIf sopsCfg.enable {
        sops.secrets = {
          garage_env = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
        };

        services.garage = {
          environmentFile = config.sops.secrets.garage_env.path; # Default: null
        };
      })
    ]
  );
}
