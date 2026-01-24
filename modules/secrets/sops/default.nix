{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) map;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.secrets.sops;
in
{
  options.yakumo.secrets.sops = {
    enable = mkEnableOption "sops-nix";
  };

  config = mkIf cfg.enable (
    let
      username = config.yakumo.user.name;
      opensshCfg = config.services.openssh;
    in
    {
      sops = {
        defaultSopsFile = ../../secrets/default.yaml;
        age = {
          sshKeyPaths =
            if opensshCfg.enable then
              map (k: k.path) opensshCfg.hostKeys
            else
              [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
        # NOTE: Add a new secret here whenever created.
        secrets = {
          login_password_otogaki.sopsFile = ../../secrets/default.yaml;
          login_password_rkawata.sopsFile = ../../secrets/default.yaml;
          gh_token_for_mcp.sopsFile = ../../secrets/default.yaml;
          git_signing_key = {
            sopsFile = ../../../users/${username}/secrets/default.yaml;
            owner = username;
          };
        };
      };
    }
  );
}
