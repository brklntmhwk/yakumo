{
  config,
  options,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkAliasDefinitions
    mkDefault
    mkForce
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
    users.mutableUsers = mkForce false;

    yakumo.user = {
      description = mkDefault cfg.name;
      extraGroups = mkDefault [ "wheel" ];
      group = mkDefault "yakumo";
      # If set to true, this sets:
      # - 'createHome' to true
      # - 'home' to '/home/<username>'
      # - 'useDefaultShell' to true
      # - 'isSystemUser' to false
      isNormalUser = mkDefault true;
      uid = mkDefault 1000;
    };
  };
}
