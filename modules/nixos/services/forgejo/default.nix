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
  cfg = config.yakumo.services.forgejo;
in
{
  options.yakumo.services.forgejo = {
    enable = mkEnableOption "forgejo";
  };

  config = mkIf cfg.enable {
    services.forgejo = (
      let
        forgejoCfg = config.services.forgejo;
      in
      {
        enable = true;
        database = {
          createDatabase = true; # Default: true
          type = "postgres"; # Default: 'sqlite3' (Options: 'mysql', 'postgres')
          name = "forgejo"; # Default: 'forgejo'
          host = "127.0.0.1"; # Default: '127.0.0.1'
          user = "forgejo"; # Default: 'forgejo'
          # Use port 5432 for PostgreSQL DB.
          port = 5432;
          path = "${forgejoCfg.stateDir}/data/forgejo.db";
          passwordFile = config.sops.secrets.xxx.path;
          socket = "/run/mysqld/mysqld.sock";
        };
        dump = {
          enable = true; # Default: false
          # (Options: 'tar', 'tar.sz', 'tar.gz', 'tar.xz', 'tar.bz2', 'tar.br', 'tar.lz4', 'tar.zst')
          type = "zip"; # Default: 'zip'
          age = "4w"; # Default: '4w'
          backupDir = "${forgejoCfg.stateDir}/dump";
          # Specify the filename for the dump.
          # If null, Forgejo uses the default name.
          file = "forgejo-dump"; # Default: null
          # Run a Forgejo dump at this interval.
          interval = "04:31"; # Default: '04:31' (Options: 'hourly', etc.)
        };
        # LFS (Large File Storage)
        lfs = {
          enable = true; # Default: false
          contentDir = "${forgejoCfg.stateDir}/data/lfs";
        };
        group = "forgejo"; # Default: 'forgejo'
        user = "forgejo"; # Default: 'forgejo'
        customDir = "${forgejoCfg.stateDir}/custom";
        stateDir = "/var/lib/forgejo";
        repositoryRoot = "${forgejoCfg.stateDir}/repositories";
        useWizard = false; # Default: false
        secrets = { };
        settings = {
          log = {
            LEVEL = "Info"; # Default: 'Info' (Options: 'Trace', 'Debug', 'Warn', 'Error', 'Critical')
            ROOT_PATH = "${forgejoCfg.stateDir}/log";
          };
          server = {
            DISABLE_SSH = false; # Default: false
            DOMAIN = "localhost"; # Default: 'localhost'
            # Set this so it aligns with `PROTOCOL`.
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = 3000; # Default: '3000'
            PROTOCOL = "http"; # Default: 'http' (Options: 'https', 'fcgi', 'http+unix', 'fcgi+unix')
            ROOT_URL = "http://${forgejoCfg.settings.server.DOMAIN}:${toString forgejoCfg.settings.server.HTTP_PORT}/";
            SSH_PORT = 22; # Default: '2222'
            STATIC_ROOT_PATH = forgejoCfg.package.data;
          };
          session = {
            COOKIE_SECURE = false; # Default: false
          };
        };
      }
    );
  };
}
