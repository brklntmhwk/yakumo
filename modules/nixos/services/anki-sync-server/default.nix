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
in
{
  options.yakumo.services.anki-sync-server = {
    enable = mkEnableOption "anki-sync-server";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable {
    services.anki-sync-server = {
      enable = true;
      address = "::1"; # Default: '::1'
      baseDirectory = "%S/%N"; # Default: '%S/%N'
      openFirewall = true; # Default: false
      port = 27701; # Default: 27701
      users = [
        {
          username = config.yakumo.user.name;
          passwordFile = config.sops.secrets.xxx.path;
        }
      ];
    };

    services.caddy.virtualHosts = (
      let
        inherit (ankiSyncSrvCfg) address port;
        ankiSyncSrvCfg = config.services.anki-sync-server;
      in
      {
        "${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy [${address}]:${builtins.toString port}
          '';
        };
      }
    );
  };
}
