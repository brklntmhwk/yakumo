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
  cfg = config.yakumo.services.garage;
in
{
  options.yakumo.services.garage = {
    enable = mkEnableOption "garage";
  };

  config = mkIf cfg.enable {
    services.garage = {
      enable = true;
      environmentFile = config.sops.secrets.xxx.path; # Default: null
      extraEnvironment = { };
      logLevel = "info"; # Default: 'info' (Options: 'debug', 'error', 'trace', 'warn')
      settings = { };
    };
  };
}
