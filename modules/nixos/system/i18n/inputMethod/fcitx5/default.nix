{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;
  inherit (murakumo.utils) anyEnabled;
  cfg = config.yakumo.system.i18n.inputMethod.fcitx5;
  compositorsCfg = config.yakumo.desktop.compositors;
in {
  options.yakumo.system.i18n.inputMethod.fcitx5 = {
    enable = mkEnableOption "fcitx5";
    extraAddons = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "List of addon packages.";
    };
    # https://github.com/NixOS/nixpkgs/commit/2c2cb598fe4e59edc310962517437cafe74d0896
    quickPhrase = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          smile = "（・∀・）";
          angry = "(￣ー￣)";
        }
      '';
      description = "Quick phrases to expand.";
    };
  };

  config = mkIf cfg.enable (let
    emacsCfg = config.yakumo.editors.emacs;
    mozcPkg = if emacsCfg.enable then
      pkgs.fcitx5-mozc.overrideAttrs (old: {
        bazelTargets = old.bazelTargets
          ++ [ "unix/emacs:mozc_emacs_helper" ];
        postInstall = (old.postInstall or "") + ''
          install -Dm555 bazel-bin/unix/emacs/mozc_emacs_helper $out/bin/mozc_emacs_helper
        '';
      })
    else
      pkgs.fcitx5-mozc;
  in {
    i18n.inputMethod = {
      type = "fcitx5";
      fcitx5 = {
        addons = [ mozcPkg ] ++ cfg.extraAddons;
        quickPhrase = cfg.quickPhrase;
        waylandFrontend = anyEnabled compositorsCfg;
      };
    };
  });
}
