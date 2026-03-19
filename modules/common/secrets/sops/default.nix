{
  config,
  lib,
  pkgs,
  rootPath,
  ...
}:

{
  # Add these to platform-spicific module files instead.
  # imports = [
  #   inputs.sops-nix.nixosModules.default
  #   inputs.sops-nix.darwinModules.default
  # ];

  config =
    let
      inherit (builtins) map;
      inherit (lib) elem mkIf;
      opensshCfg = config.services.openssh;
      xdgCfg = config.yakumo.xdg;
      hardwareMods = config.yakumo.hardware.modules;
    in
    {
      sops = {
        # Only set global options here.
        # Local (i.e., user or host-scoped) options like `sops.secrets.*`
        # should be set in each host & user configurations.
        defaultSopsFile = rootPath + "/secrets/default.yaml";
        age = {
          # YubiKey doesn't officially support Age, so we use age-plugin-yubikey
          # and the PIV feature to register it in a YubiKey.
          # We use it as the admin key to Sops.
          plugins = mkIf (elem "token/yubikey/piv" hardwareMods) [ pkgs.age-plugin-yubikey ];
          # This results in:
          # "sops-install-secrets: Imported /etc/ssh/ssh_host_ed25519_key as age key with fingerprint age1..."
          sshKeyPaths =
            if opensshCfg.enable then
              map (k: k.path) opensshCfg.hostKeys
            else
              [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
      };

      environment = {
        variables = mkIf xdgCfg.enable {
          SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
        };
        systemPackages = mkIf (elem "token/yubikey/piv" hardwareMods) [ pkgs.age-plugin-yubikey ];
      };
    };
}
