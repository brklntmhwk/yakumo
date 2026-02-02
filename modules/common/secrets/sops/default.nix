{
  config,
  lib,
  ...
}:

let
  inherit (builtins) map;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.secrets.sops;
in
{
  # Add these to platform-spicific module files instead.
  # imports = [
  #   inputs.sops-nix.nixosModules.default
  #   inputs.sops-nix.darwinModules.default
  # ];

  options.yakumo.secrets.sops = {
    enable = mkEnableOption "sops-nix";
  };

  config = mkIf cfg.enable (
    let
      userCfg = config.users.users;
      opensshCfg = config.services.openssh;
    in
    {
      sops = {
        defaultSopsFile = ../../../../secrets/default.yaml;
        age = {
          sshKeyPaths =
            if opensshCfg.enable then
              map (k: k.path) opensshCfg.hostKeys
            else
              [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
        # NOTE: Add a new secret here whenever created.
        secrets = {
          login_password_otogaki.sopsFile = {
            sopsFile = ../../../../secrets/default.yaml;
            owner = userCfg.otogaki.name;
          };
          login_password_rkawata.sopsFile = {
            sopsFile = ../../../../secrets/default.yaml;
            owner = userCfg.rkawata.name;
          };
          gh_token_for_mcp.sopsFile = ../../../../secrets/default.yaml;
          git_signing_key_otogaki = {
            sopsFile = ../../../../users/otogaki/secrets/default.yaml;
            owner = userCfg.otogaki.name;
          };
          git_signing_key_rkawata = {
            sopsFile = ../../../../users/rkawata/secrets/default.yaml;
            owner = userCfg.rkawata.name;
          };
        };
      };
    }
  );
}
