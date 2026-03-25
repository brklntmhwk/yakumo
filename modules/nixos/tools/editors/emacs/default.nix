{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.yakumo.tools.editors.emacs;
in
{
  imports = [
    inputs.nix-maid.nixosModules.default
    inputs.ametsuchi.maidModules.ametsuchi
  ];

  options.yakumo.tools.editors.emacs = {
    enable = mkEnableOption "emacs";
    ametsuchi = {
      enable = mkEnableOption "Ametsuchi";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.ametsuchi.enable {
      programs.ametsuchi = {
        enable = true;
        directory = ".local/share/emacs";
        emacsclient.enable = true;
        serviceIntegration.enable = true;
      };
    })
    (mkIf (!cfg.ametsuchi.enable) {
      # TODO: Add non-ametsuchi emacs setup.
    })
  ]);
}
