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
  # https://github.com/hlissner/dotfiles/commit/2c31f918a45c7dd191970dff9dc9bb1c9bc8f73c
  options.yakumo.user = mkOption {
    type = types.attrs;
    default = {
      name = "";
    };
    description = "Alias for users.users.<username>.";
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
