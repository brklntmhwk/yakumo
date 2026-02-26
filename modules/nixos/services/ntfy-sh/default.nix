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
  cfg = config.yakumo.services.ntfy-sh;
in
{
  options.yakumo.services.ntfy-sh = {
    enable = mkEnableOption "ntfy-sh";
  };

  config = mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      group = "ntfy-sh"; # Default: 'ntfy-sh'
      user = "ntfy-sh"; # Default: 'ntfy-sh'
      environmentFile = config.sops.secrets.xxx.path; # Default: null
      # For the available settings, see:
      # https://docs.ntfy.sh/config/#config-options
      settings = { };
    };
  };
}
