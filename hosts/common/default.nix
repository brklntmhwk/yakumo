{
  config,
  lib,
  murakumo,
  ...
}:

let
  inherit (lib) mkIf optional;
  inherit (murakumo.utils) anyHasPrefix;
  systemRole = config.yakumo.system.role;
  hardwareMods = config.yakumo.hardware.modules;
  netManager = config.yakumo.system.networking.manager;
in
{
  yakumo = {
    system = {
      persistence.yosuga = {
        enable = true;
        directories = [
          "/etc/nixos"
          "/var/log/journal"
          "/var/lib/nixos"
          "/var/lib/systemd/timers"
        ]
        ++ optional (anyHasPrefix "bluetooth" hardwareMods) "/var/lib/bluetooth"
        ++ optional (netManager == "networkmanager") "/etc/NetworkManager/system-connections";
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ];
      };
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
