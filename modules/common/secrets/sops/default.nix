{
  config,
  lib,
  flakeRoot,
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
      opensshCfg = config.services.openssh;
    in
    {
      sops = {
        # Only set global options here.
        # Local options like `sops.secrets.*` should be set in each host & user
        # configurations.
        defaultSopsFile = flakeRoot + "/secrets/default.yaml";
        age = {
          sshKeyPaths =
            if opensshCfg.enable then
              builtins.map (k: k.path) opensshCfg.hostKeys
            else
              [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
      };
    };
}
