{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    types
    ;
  cfg = config.yakumo.services.openssh;
  systemRole = config.yakumo.system.role;
in
{
  options.yakumo.services.openssh = {
    enable = mkEnableOption "openssh";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.openssh = {
        enable = true;
        settings = {
          # Hardening: Disable password auth entirely.
          # Reliance on SSH keys (ed25519) is strictly enforced.
          KbdInteractiveAuthentication = false;
          PasswordAuthentication = false;
          # Hardening: Disable root login.
          # PermitRootLogin = mkForce "no";
        };
        # Force only the ed25519 keys.
        # By default, this contains both RSA & ed25519 keys.
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
            # Higher numbers result in slower passphrase verification but
            # increased resistance to brute-force attacks should the keys be stolen.
            rounds = 100; # Default: 16
          }
        ];
        # https://github.com/hlissner/dotfiles/commit/9dbe3a62865cf51b9982236d52df271c93e4f013
        # Invalidate shorter (i.e., weak) moduli than 3072 as a hedge against
        # the Logjam Attack (2015).
        # The 5th column lists the bit size of the prime number used for encryption.
        # Other options: 2048, 4096.
        moduliFile = pkgs.runCommand "filterModuliFile" {} ''
          awk '$5 >= 3071' "${config.programs.ssh.package}/etc/ssh/moduli" >"$out"
        '';
      };
    }
    (mkIf (systemRole == "workstation") {
      # With this, Systemd will start OpenSSH on the first incoming connection
      # instead of having it permanently running as a daemon.
      services.openssh.startWhenNeeded = true;
    })
  ]);
}
