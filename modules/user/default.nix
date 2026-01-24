{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkAliasDefinitions
    mkDefault
    mkIf
    mkOption
    types
    ;
  cfg = config.yakumo.user;
in
{
  options.yakumo.user = {
    name = mkOption {
      type = types.str;
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg ? name;
        message = "Username must be set";
      }
    ];

    # Prefer 'yakumo.user.*' over 'users.users.<username>.*'.
    users.users.${cfg.name} = mkAliasDefinitions options.yakumo.user;

    # Disable mutable users.
    users.mutableUsers = false;

    yakumo.user = {
      description = mkDefault cfg.name;
      extraGroups = mkDefault [ "wheel" ];
      group = mkDefault "users";
      isNormalUser = mkDefault true;
      uid = mkDefault 1000;
    };
  };
}
