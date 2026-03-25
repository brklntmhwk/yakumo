{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf;
  isWsl = (config ? wsl) && config.wsl.enable;
  systemRole = config.yakumo.system.role;
in
{
  yakumo = {
    system = {
      persistence.yosuga = mkIf (!isWsl) {
        enable = true;
        directories = [
          "/etc/nixos"
          "/var/log/journal"
          "/var/lib/nixos"
          "/var/lib/systemd/timers"
        ];
        files = [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ecdsa_key"
          "/etc/ssh/ssh_host_ecdsa_key.pub"
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
  };
}
