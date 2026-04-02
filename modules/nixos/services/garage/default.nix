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
        settings =
          let
            inherit (meta)
              address
              bindAddress
              domain
              extraPorts
              port
              ;
          in
          {
            admin = {
              api_bind_addr = "${address}:${extraPorts.admin}";
              admin_token = config.sops.secrets."garage/admin_token".path;
            };
            data_dir = "";
            s3_api = {
              api_bind_addr = "${address}:${extraPorts.api}";
              s3_region = "garage";
              root_domain = domain;
            };
            s3_web = {
              bind_addr = bindAddress;
              root_domain = domain;
            };
            replication_factor = 1;
          };
      };

      sops.secrets = {
        "garage/env_file" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
        "garage/admin_token" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
      };
    }
  ]);
}
