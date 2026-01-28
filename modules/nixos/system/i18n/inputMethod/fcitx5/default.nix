{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;
  inherit (murakumo.utils) anyEnabled;
  cfg = config.yakumo.system.i18n.inputMethod.fcitx5;
  compositorsCfg = config.yakumo.desktop.compositors;
in
{
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

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      type = "fcitx5";
      fcitx5 = {
        addons =
          builtins.attrValues {
            inherit (pkgs) fcitx5-mozc;
          }
          ++ cfg.extraAddons;
        quickPhrase = cfg.quickPhrase;
        waylandFrontend = anyEnabled compositorsCfg;
      };
    };
  };
}
