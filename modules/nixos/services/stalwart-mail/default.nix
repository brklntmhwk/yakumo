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
  };
}
