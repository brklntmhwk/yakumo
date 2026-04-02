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
  cfg = config.yakumo.services.garage;
  meta = config.yakumo.services.metadata.garage;
in
{
  options.yakumo.services.garage = {
    enable = mkEnableOption "garage";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.garage = {
        enable = true;
        environmentFile = config.sops.secrets."garage/env_file".path; # Default: null
        extraEnvironment = { };
        logLevel = "info"; # Default: 'info' (Options: 'debug', 'error', 'trace', 'warn')
        settings = { };
      };

      sops.secrets = {
        "garage/env_file" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
      };
    }
  ]);
}
