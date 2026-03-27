{ lib }:

let
  inherit (lib)
    literalExpression
    mkOption
    types
    ;
in
rec {
  syncProfile =
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

  profile =
    { ... }:
    {
      options = {
        default = mkEnableOption "Opening this profile on startup";
        sync = mkOption {
          type = types.submodule syncProfile;
          default = { };
          description = "Options related to Anki's sync features.";
        };
      };
    };

  ankiSettings =
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
          type = types.attrsOf (types.submodule profile);
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
}
