{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  roles = [
    "server"
    "workstation"
  ];
  subroles = [
    "mail"
    "multi"
    "smart-home"
  ];
  cfg = config.yakumo.system;
in
{
  options.yakumo.system = {
    role = mkOption {
      type = types.enum roles;
      default = "workstation";
    };
    subrole = mkOption {
      type = types.nullOr (types.enum subroles);
      default = null;
      description = ''
        Sub-role for server configuration.
        This will be ignored when role != "server".
      '';
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = (cfg.role == "server") -> (cfg.subrole != null);
          message = "A sub-role must be set when role = server";
        }
        {
          assertion = (cfg.role != "server") -> (cfg.subrole == null);
          message = "A sub-role is an exclusive option to server";
        }
      ];
    }
  ];
}
