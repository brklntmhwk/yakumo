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
  cfg = config.yakumo.services.vaultwarden;
in
{
  options.yakumo.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      backupDir = "/var/backup/vaultwarden"; # Default: null
      # Use Caddy instead.
      configureNginx = false; # Default: false
      configurePostgres = true; # Default: false
      dbBackend = "postgresql"; # Default: 'sqlite' (Options: 'mysql', 'postgresql')
      domain = "";
      environmentFile = "/var/lib/vaultwarden.env";
      config = {
        ROCKET_ADDRESS = "::1";
        ROCKET_PORT = 8222;
      };
    };
  };
}
