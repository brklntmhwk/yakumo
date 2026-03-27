# Based on:
# https://github.com/nix-community/home-manager/blob/c6fe2944ad9f2444b2d767c4a5edee7c166e8a95/modules/programs/anki/default.nix
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
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.tools.misc.anki;
  helper = import ./_helper.nix { inherit lib config pkgs; };
  submodules = import ./_submodules.nix { inherit lib; };
in
{
  options.yakumo.tools.misc.anki = {
    enable = mkEnableOption "anki";
    addons = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "List of Anki add-on packages to install.";
      example = literalExpression ''
        [
          pkgs.ankiAddons.anki-connect
          pkgs.ankiAddons.passfail2.withConfig {
            config = {
              again_button_name = "not quite";
              good_button_name = "excellent";
              toggle_names_textcolors = 1;
            };
          };
        ]
      '';
    };
    settings = mkOption {
      type = types.submodule submodules.ankiSettings;
      default = { };
      description = ''
        Anki settings as a Nix attribute set.
        These settings are applied as a baseline only. Users can imperatively mutate
        settings via the Anki GUI afterwards.
      '';
      example = literalExpression ''
        {
          videoDriver = "opengl";
          theme = "dark";
          language = "ja_JP";
          style = "native";
          uiScale = 2.0;
          hideBottomBar = true;
          hideBottomBarMode = "fullscreen";
          hideTopBar = false;
          hideTopBarMode = "always";
          legacyImportExport = false;
          minimalistMode = true;
          reduceMotion = true;
          spacebarRatesCard = true;
          answerKeys = [
            {
              ease = 1;
              key = "left";
            }
            {
              ease = 2;
              key = "up";
            }
          ];
          profiles = {
            foo = {
              default = true;
              sync = {
                username = "foo@bar.com";
                passwordFile = pkgs.writeText "foo-key-file" "foo-sync-key";
                url = "http://foo.com/anki-sync/";
                networkTimeout = 60;
                autoSync = true;
                syncMedia = true;
                autoSyncMediaMinutes = 15;
              };
            };
          };
        }
      '';
    };
    package = mkPackageOption pkgs "anki" { };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) toJSON;
      inherit (lib) getName;
      inherit (pkgs) writeText;
      inherit (murakumo.wrappers) mkWrapper;

      # Serialize Nix settings to JSON for the Python bootstrapper.
      ankiConfigJson = writeText "anki-config.json" (toJSON cfg.settings);

      # Base Anki package with configured addons.
      baseAnki = cfg.package.withAddons cfg.addons;

      # Wrap the Anki binary to inject the bootstrapper execution prior to GUI launch.
      wrappedAnki = mkWrapper {
        pkg = baseAnki;
        name = "${getName baseAnki}-${config.yakumo.user.name}";
        preCommands = [
          ''
            ANKI_BASE="''${XDG_DATA_HOME:-$HOME/.local/share}/Anki2"
            mkdir -p "$ANKI_BASE"

            # Extract PYTHONPATH from the upstream Anki package and apply it to the current shell.
            eval "$(${pkgs.gnugrep}/bin/grep -E '^export PYTHONPATH=' ${baseAnki}/bin/anki)"

            ${pkgs.python3}/bin/python3 ${helper.bootstrapperScript} "$ANKI_BASE" ${ankiConfigJson}
          ''
        ];
      };
    in
    {
      yakumo.user.packages = [ wrappedAnki ];
    }
  );
}
