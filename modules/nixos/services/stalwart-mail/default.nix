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
  cfg = config.yakumo.services.stalwart-mail;
in
{
  options.yakumo.services.stalwart-mail = {
    enable = mkEnableOption "satlwart-mail";
  };

  config = mkIf cfg.enable {
    services.stalwart-mail = {
      enable = true;
      openFirewall = false; # Default: false
      dataDir = "/var/lib/stalwart-mail";
      # Set credentials env vars to configure Stalwart-Mail secrets.
      # These secrets can be accessed in configuration values with the macros such as
      # %{file:/run/credentials/stalwart-mail.service/VAR_NAME}%.
      # For the macro syntax, see: https://stalw.art/docs/configuration/macros
      credentials = { };
      # For the available options, see:
      # https://stalw.art/docs/category/configuration/
      settings = { };
    };

    yakumo.services.rustic.backups = {
      stalwart = {
        environmentFile = config.sops.secrets.xxx.path;
        timerConfig = {
          OnCalendar = "*-*-* 03:00:00"; # Run daily at 3 a.m.
          Persistent = true;
        };
        settings = {
          repository = "";
          backup = {
            sources = [ "/var/lib/stalwart-mail" ];
          };
          forget = {
            keep-daily = 7;
            keep-weekly = 4;
            keep-monthly = 6;
            prune = true;
          };
        };
      };
    };
  };
}
