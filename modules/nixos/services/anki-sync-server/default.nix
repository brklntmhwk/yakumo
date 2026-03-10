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
  cfg = config.yakumo.services.anki-sync-server;
  meta = config.yakumo.services.metadata.anki-sync-server;
in
{
  options.yakumo.services.anki-sync-server = {
    enable = mkEnableOption "anki-sync-server";
  };

  config = mkIf cfg.enable {
    services.anki-sync-server = {
      inherit (meta)
        address # Default: '::1'
        port # Default: 27701
        ;
      enable = true;
      baseDirectory = "%S/%N"; # Default: '%S/%N'
      openFirewall = true; # Default: false
      users = [
        {
          username = config.yakumo.user.name;
          passwordFile = config.sops.secrets.anki_sync_server_passwd.path;
        }
      ];
    };

    yakumo.services.metadata.anki-sync-server.reverseProxy = {
      caddyIntegration.enable = true;
    };
  };
}
