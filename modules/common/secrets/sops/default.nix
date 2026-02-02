{
  config,
  lib,
  flakeRoot,
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
      username = config.yakumo.user.name;
      userCfg = config.users.users;
      opensshCfg = config.services.openssh;
    in
    {
      sops = {
        defaultSopsFile = flakeRoot + "/secrets/default.yaml";
        age = {
          sshKeyPaths =
            if opensshCfg.enable then
              map (k: k.path) opensshCfg.hostKeys
            else
              [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
        # NOTE: Add a new secret here whenever created.
        secrets = {
          login_password_otogaki = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
          login_password_rkawata = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
          gh_token_for_mcp.sopsFile = flakeRoot + "/secrets/default.yaml";
          git_signing_key = {
            sopsFile = flakeRoot + "/users/${username}/secrets/default.yaml";
            owner = username;
          };
        };
      };
    }
  );
}
