{ config, lib, ... }:

let
  inherit (lib) mkIf;
  systemRole = config.yakumo.system.role;
in
{
  yakumo = {
    system = {
      # persistence.yosuga = {
      #   enable = true;
      # };
    };
    security = {
      acme.enable = mkIf (systemRole == "server") true;
    };
    services = {
      openssh.enable = true;
    };
    xdg.enable = true;
  };
}
