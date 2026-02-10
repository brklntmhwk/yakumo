{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib) mkIf mkOption types;
  inherit (murakumo.utils) anyEnabled;
  cfg = config.yakumo.system.i18n.inputMethod;
in { config = mkIf (anyEnabled cfg) { i18n.inputMethod.enable = true; }; }
