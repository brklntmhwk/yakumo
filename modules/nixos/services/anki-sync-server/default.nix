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
  cfg = config.yakumo.services.anki-sync-server;
in
{
  options.yakumo.services.anki-sync-server = {
    enable = mkEnableOption "anki-sync-server";
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
  };
}
