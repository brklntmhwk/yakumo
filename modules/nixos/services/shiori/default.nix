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
    mkOption
    types
    ;
  cfg = config.yakumo.services.shiori;
in
{
  options.yakumo.services.shiori = {
    enable = mkEnableOption "shiori";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable {
    services.shiori = {
      enable = true;
      # If empty, Shiori listens on all interfaces.
      address = "127.0.0.1"; # Default: ''
      # Shiori can use MySQL or PostgreSQL.
      databaseUrl = "postgres:///shiori?host=/run/postgresql";
      environmentFile = config.sops.secrets.xxx.path; # Default: null
      port = 8080; # Default: 8080
      webRoot = "/"; # Default: '/'
    };

    services.caddy.virtualHosts =
      let
        shioriCfg = config.services.shiori;
      in
      {
        "${cfg.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${shioriCfg.address}:${builtins.toString shioriCfg.port}
          '';
        };
      };
  };
}
