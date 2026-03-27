{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    concatMapStringsSep
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (pkgs) writeText;
  inherit (murakumo.platforms) isDarwin isLinux;
  cfg = config.yakumo.tools.misc.ssh;
  userCfg = config.yakumo.user;
  submodules = import ./_submodules.nix { inherit lib; };

  fileContent =
    concatMapStringsSep "\n" (signer: "${signer.email} ${signer.key}") cfg.allowedSigners + "\n";
  allowedSignersFile = writeText "allowed_signers" fileContent;
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
    (mkIf isDarwin {
      system.activationScripts = {
        sshAllowedSignersSetup.text = mkIf (cfg.allowedSigners != [ ]) ''
          mkdir -m 0700 -p ${userCfg.home}/.ssh
          cp ${allowedSignersFile} ${userCfg.home}/.ssh/allowed_signers
          chown ${userCfg.name} ${userCfg.home}/.ssh/allowed_signers
          chmod 0644 ${userCfg.home}/.ssh/allowed_signers
        '';
      };
    })
    (mkIf isLinux {
      # 'd': Create directory if it doesn't exist.
      # 'L+': Create a symlink if it doesn't exist. If a file or a directory already
      # exists where the symlink is to be created, remove and replace it.
      # Format: Type Path Mode User Group Age Argument
      systemd.tmpfiles.rules = mkIf (cfg.allowedSigners != [ ]) [
        "d ${userCfg.home}/.ssh 0700 ${userCfg.name} ${userCfg.name} - -"
        "L+ ${userCfg.home}/.ssh/allowed_signers - - - - ${allowedSignersFile}"
      ];
    })
  ];
}
