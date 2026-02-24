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
  cfg = config.yakumo.services.samba;
in
{
  options.yakumo.services.samba = {
    enable = mkEnableOption "samba";
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = false; # Default: false
      # Enable WINS NSS (Name Service Switch) plugin if set to true.
      # Doing so allows apps to resolve WINS/NetBIOS names
      # (a.k.a. Windows machine names) by transparently querying the winbindd daemon.
      nsswins = false; # Default: false
      nmbd = {
        enable = true; # Default: true
        extraArgs = [ ];
      };
      smbd = {
        enable = true; # Default: true
        extraArgs = [ ];
      };
      usershares = {
        enable = false; # Default: false
        group = "samba"; # Default: 'samba'
      };
      winbindd = {
        enable = true; # Default: true
        extraArgs = [ ];
      };
      settings.global = {
        "invalid users" = [
          "root"
        ];
        "passwd program" = "/run/wrappers/bin/passwd %u";
        security = "user"; # Default: 'user' (Options: 'auto', 'domain', 'ads')
      };
    };
  };
}
