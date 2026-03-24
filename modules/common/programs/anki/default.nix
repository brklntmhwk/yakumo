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
  cfg = config.yakumo.programs.anki;
  helper = import ./helper.nix { inherit lib config pkgs; };

  syncProfileSubmodule =
    { ... }:
    {
      options = {
        username = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Sync account username.";
          example = "foo@bar.com";
        };
        passwordFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            Path to the file containing the sync account password.
            This is different from the account password.
          '';
        };
        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Custom sync server URL.
            For more details, see:
            <https://docs.ankiweb.net/sync-server.html>.
          '';
          example = "http://example.com/anki-sync/";
        };
        networkTimeout = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Network timeout in seconds (clamped between 30 and 99999).";
          example = 60;
        };
        autoSync = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Automatically sync on profile open/close.";
          example = true;
        };
        syncMedia = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Synchronize audio and images too.";
          example = true;
        };
        autoSyncMediaMinutes = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = ''
            Automatically sync media every X minutes.
            Set this to 0 to disable periodic media syncing.
          '';
          example = 15;
        };
      };
    };
  profileSubmodule =
    { ... }:
    {
      options = {
        default = mkEnableOption "Opening this profile on startup";
        sync = mkOption {
          type = types.submodule syncProfileSubmodule;
          default = { };
          description = "Options related to Anki's sync features.";
        };
      };
    };
  ankiSettingsSubmodule =
    { ... }:
    {
      options = {
        videoDriver = mkOption {
          type = types.nullOr (
            types.enum [
              "angle"
              "auto"
              "d3d11"
              "metal"
              "opengl"
              "software"
              "vulkan"
            ]
          );
          default = null;
          description = "Video driver to use.";
          example = "vulkan";
        };
        theme = mkOption {
          type = types.nullOr (
            types.enum [
              "system"
              "light"
              "dark"
            ]
          );
          default = null;
          description = "Theme to apply.";
          example = "dark";
        };
        language = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Language in which the desktop app appears.
            For the supported tags, see:
            <https://github.com/ankitects/anki/blob/main/pylib/anki/lang.py>
          '';
          example = "ja_JP";
        };
        style = mkOption {
          type = types.nullOr (
            types.enum [
              "anki"
              "native"
            ]
          );
          default = null;
          description = "Widget style to apply.";
          example = "native";
        };
        uiScale = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "User interface scale.";
          example = 1.0;
        };
        hideBottomBar = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Hide bottom bar during review.";
          example = true;
        };
        hideBottomBarMode = mkOption {
          type = types.nullOr (
            types.enum [
              "fullscreen"
              "always"
            ]
          );
          default = null;
          description = "When to hide the top bar where `hideBottomBar` is enabled.";
          example = "fullscreen";
        };
        hideTopBar = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Hide top bar during review.";
          example = true;
        };
        hideTopBarMode = mkOption {
          type = types.nullOr (
            types.enum [
              "fullscreen"
              "always"
            ]
          );
          default = null;
          description = "When to hide the top bar where `hideTopBar` is enabled.";
          example = "fullscreen";
        };
        legacyImportExport = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Use legacy (pre 2.1.55) import/export handling code.";
          example = true;
        };
        minimalistMode = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Minimalist user interface mode.";
          example = true;
        };
        reduceMotion = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Disable various animations and transitions of the user interface.";
          example = true;
        };
        spacebarRatesCard = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Spacebar (or enter) also answers card.";
          example = true;
        };
        answerKeys = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                ease = mkOption {
                  type = types.ints.between 1 4;
                  description = ''
                    Number associated with an answer button.
                    By default, 1 = Again, 2 = Hard, 3 = Good, and 4 = Easy.
                  '';
                  example = 3;
                };
                key = mkOption {
                  type = types.str;
                  description = ''
                    Keyboard shortcut for this answer button.
                    The shortcut should be in the string format used by:
                    <https://doc.qt.io/qt-6/qkeysequence.html>
                  '';
                  example = "left";
                };
              };
            }
          );
          default = [ ];
          description = ''
            Overrides for choosing what keyboard shortcut activates each
            answer button. The Anki default will be used for ones without an
            override defined.
          '';
          example = [
            {
              ease = 1;
              key = "left";
            }
            {
              ease = 2;
              key = "up";
            }
            {
              ease = 3;
              key = "right";
            }
            {
              ease = 4;
              key = "down";
            }
          ];
        };
        profiles = mkOption {
          type = types.attrsOf (types.submodule profileSubmodule);
          default = {
            "User 1" = { };
          };
          description = ''
            Anki profiles and their settings.
            Profiles are primarily intended to be one per person,
            are not recommended for splitting up your own content.
          '';
          example = literalExpression ''
            {
              foo = {
                default = true;
                sync = {
                  username = "foo@bar.com";
                  passwordFile = pkgs.writeText "foo-key-file" "foo-sync-key";
                };
              };
            }
          '';
        };
      };
    };
in
{
  options.yakumo.programs.anki = {
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
      type = types.submodule ankiSettingsSubmodule;
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
