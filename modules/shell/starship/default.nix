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
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.shell.starship;
  zshCfg = config.yakumo.shell.zsh;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.yakumo.shell.starship = {
    enable = mkEnableOption "starship";
    # https://github.com/nix-community/home-manager/commit/7205d3b2d2192b6f0d3fe54a4cf38525ec4e27f5
    settings = mkOption {
      type =
        let
          inherit (types)
            attrsOf
            bool
            either
            int
            listOf
            str
            ;
          primitive = either bool (either int str);
          primitivesOrPrimAttrs = either primitive (attrsOf primitive);
          entry = either primitive (listOf primitivesOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in
        attrsOf entries;
      default = { };
      description = ''
        Starship configuraion in Nix-representable TOML format.
        For the valid setting options, see: https://starship.rs/config/
      '';
      example = literalExpression ''
        {
          add_newline = false;
          format = lib.concatStrings [
            "$line_break"
            "$package"
            "$line_break"
            "$character"
          ];
          scan_timeout = 10;
          character = {
            success_symbol = "➜";
            error_symbol = "➜";
          };
        }
      '';
    };
    package = mkPackageOption pkgs "starship" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Starship package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions =
        let
          inherit (murakumo.utils) anyAttrs;

          isEnabled = _: v: v.enable or false;
          hasStarshipEnabled = cfg: (anyAttrs isEnabled cfg) || !(anyAttrs (_: v: v.settings or false) cfg);
        in
        [
          {
            assertion = hasStarshipEnabled cfg;
            message = "Starship settings cannot be added without itself being enabled anyway";
          }
        ];
    }
    (
      let
        inherit (lib) getExe getName;
        inherit (murakumo.wrappers) mkAppWrapper;

        starshipToml = tomlFormat.generate "starship.toml" cfg.settings;
        starshipWrapped = mkAppWrapper {
          pkgs = cfg.package;
          name = "${getName cfg.package}-${config.yakumo.user.name}";
          env = {
            STARSHIP_CONFIG = starshipToml;
          };
        };
      in
      {
        yakumo.user.packages = [ starshipWrapped ];
        yakumo.shell.starship.packageWrapped = starshipWrapped;
        yakumo.shell.zsh = mkIf zshCfg.enable {
          initExtraLast = ''
            eval "$(${getExe starshipWrapped} init zsh)"
          '';
        };

        # This writes things as follows to every shell's `promptInit` or `shellInit` for you:
        # - The `eval "$(starship init bash)"` thingy
        # - The `export STARSHIP_CONFIG=${settingsFile}` thingy if the config file
        # doesn't exist under the XDG config dir.
        # https://github.com/NixOS/nixpkgs/commit/928c8115ba60d54ec36b3f11a364ff81b0ad066c
        # programs.starship = {
        #   enable = true;
        #   settings = cfg.settings;
        #   package = cfg.package;
        # };
      }
    )
  ]);
}
