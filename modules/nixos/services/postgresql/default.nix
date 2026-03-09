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
  cfg = config.yakumo.services.postgresql;
  meta = config.yakumo.services.metadata.postgresql;
in
{
  options.yakumo.services.postgresql = {
    enable = mkEnableOption "postgresql";
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableJIT = false; # Default: false
      enableTCPIP = false; # Default: false
      # Define how users authenticate themselves to the server.
      # By default:
      # - peer based authentication will be used for users connecting via the Unix socket.
      # - md5 password authentication will be used for users connecting via TCP.
      # Any added rules will be inserted above the default rules.
      # Use `lib.mkForce` if you want to replace the default rules entirely.
      # For the valid config format, see:
      # https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
      authentication = ""; # Default: ''
      # Check the config file syntactically at compile time.
      checkConfig = true; # Default: true
      dataDir = "/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";
      # TODO: Consider configuring these options in each module.
      ensureDatabases = [
        # Add PostgreSQL DB for each service here to ensure their presence.
      ];
      ensureUsers = [
        # Add PostgreSQL DB users for each service here to ensure their presence.
      ];
      # extensions = [];
      # Define the mapping from system users to DB users.
      # Each line should look like:
      # 'map-name-0 system-username-0 database-username-0'
      identMap = ""; # Default: ''
      # Pass additional args to `initdb` during data directory initialization.
      initdbArgs = [ ];
      # Specify a file that contains SQL statements to execute on first startup.
      initialScript = null; # Default: null
      # Configure the syscall filter for `postgresql.service`.
      # The ordering matters.
      systemCallFilter = {
        "@system-service" = true;
        "~@privileged" = true;
        "~@resources" = true;
        # This also accepts the following format with explicit priority:
        # "foobar" = {
        #   enable = true;
        #   priority = 100;
        # };
      };
      settings = {
        inherit (meta) port; # Default: 5432
        log_line_prefix = "[%p] "; # Default: '[%p] '
        shared_preload_libraries = null; # Default: null
      };
    };
  };
}
