# NOTE: Exceptionally adopting the mutable user config directory using Nix-maid.
# No CLI flag like '--config' found.
{
  inputs,
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) mapAttrs;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.programs.wthrr;
in
{
  imports = [ inputs.nix-maid.nixosModules.default ];

  options.yakumo.programs.wthrr = {
    enable = mkEnableOption "wthrr a.k.a. Weathercrab";
    settings = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Wthrr configuraion in Nix-representable RON format.
        For more details, see:
        https://github.com/hrkfdn/ncspot/blob/main/doc/users.md#configuration
      '';
      example = lib.literalExpression ''
        {
          address = "Tokyo, Japan";
          units = {
            temperature = "celsius";
            speed = "kmh";
          };
          forecast = [ "day" "week" ];
          gui.graph.style = "lines(solid)";
        }
      '';
    };
    package = mkPackageOption pkgs "wthrr" { };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins)
        isAttrs
        isList
        isString
        map
        ;
      inherit (lib) elem;
      inherit (murakumo.generators) mkRonLiteral toRon;
      processSettings =
        settings:
        let
          # Define which top-level keys should always be strings.
          stringKeys = [
            "address"
            "language"
          ];
          # Define a helper to decide if a value should be a literal or a string.
          convert =
            k: v:
            if elem k stringKeys then
              v
            else if isString v then
              mkRonLiteral v
            else if isAttrs v then
              mapAttrs convert v
            else if isList v then
              map (x: if isString x then mkRonLiteral x else x) v
            else
              v;
        in
        mapAttrs convert settings;
    in
    {
      yakumo.user.maid = {
        file = {
          xdg_config = mkIf (cfg.settings != { }) {
            # https://github.com/ttytm/wthrr-the-weathercrab?tab=readme-ov-file#config
            "weathercrab/wthrr.ron".text = toRon {
              attrs = processSettings cfg.settings;
            };
          };
        };
      };
    }
  );
}
