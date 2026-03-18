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

  config = mkIf cfg.enable (mkMerge [
    {
      services.garage = {
        enable = true;
        environmentFile = config.sops.secrets.garage_env.path; # Default: null
        extraEnvironment = { };
        logLevel = "info"; # Default: 'info' (Options: 'debug', 'error', 'trace', 'warn')
        settings = { };
      };

      sops.secrets = {
        garage_env = {
          sopsFile = flakeRoot + "/secrets/default.yaml";
        };
      };
    }
  ]);
}
