{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (murakumo.platforms) isDarwin isLinux;
  cfg = config.yakumo.tools.misc.ssh;
  submodules = import ./_submodules.nix { inherit lib; };
in
{
  options.yakumo.tools.misc.ssh = {
    allowedSigners = mkOption {
      type = types.listOf (types.submodule submodules.allowedSigners);
      default = [ ];
      description = ''
        List of allowed signers.
        Both their email addresses and SSH public keys must be provided.
      '';
    };
  };

  config = mkMerge [
    (mkIf isDarwin (
      let
        inherit (lib) concatMapStringsSep;
        inherit (pkgs) writeText;
        userCfg = config.yakumo.user;
        fileContent =
          concatMapStringsSep "\n" (signer: "${signer.email} ${signer.key}") cfg.allowedSigners + "\n";
        allowedSignersFile = writeText "allowed_signers" fileContent;
      in
      {
        system.activationScripts = {
          sshAllowedSignersSetup.text = mkIf (cfg.allowedSigners != [ ]) ''
            mkdir -m 0700 -p ${userCfg.home}/.ssh
            cp ${allowedSignersFile} ${userCfg.home}/.ssh/allowed_signers
            chown ${userCfg.name} ${userCfg.home}/.ssh/allowed_signers
            chmod 0644 ${userCfg.home}/.ssh/allowed_signers
          '';
        };
      }
    ))
    (mkIf isLinux {
      systemd.tmpfiles.rules = mkIf (cfg.allowedSigners != [ ]) [
        "d %h/.ssh 0700 - - - -"
        "L+ %h/.ssh/allowed_signers - - - - ${allowedSignersFile}"
      ];
    })
  ];
}
