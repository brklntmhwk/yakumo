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
  cfg = config.yakumo.desktop.compositors.niri;
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.yakumo.desktop.compositors.niri = {
    enable = mkEnableOption "niri";
    # https://github.com/nix-community/home-manager/commit/810e5f36131c6b6eb1bcc1e3cff23cc604e82887
    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Niri configuration in Nix-representable KDL format.
        For the valid setting options, see:
        https://yalter.github.io/niri/Configuration%3A-Introduction.html
      '';
      example = {
        input.keyboard.xkb._children = [
          {
            layout._args = [ "us" ];
            options._args = [ "terminate:ctrl_alt_bksp" ];
          }
        ];
        input.focus-follows-mouse._props.max-scroll-amount = "0%";
      };
    };
    loginSettings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Niri configuration for the greetd login session in Nix-representable KDL format.
        For the valid setting options, see:
        https://yalter.github.io/niri/Configuration%3A-Introduction.html
      '';
    };
    greeter = {
      # https://github.com/NixOS/nixpkgs/commit/ab65220a1af24cc46a67021e624fce3f4c87ebfa
      regreet = {
        enable = mkEnableOption "regreet";
        background = {
          path = mkOption {
            type = types.nullOr (types.either types.path types.str);
            default = null;
            description = ''
              Path to the background image that will be applied to the login screen.
            '';
          };
          # https://github.com/rharish101/ReGreet/commit/94aad06ef46be06765e6d9fd938df7edafcb5a04
          fit = mkOption {
            type = types.enum [
              "Contain"
              "Cover"
              "Fill"
              "ScaleDown"
            ];
            default = "Cover";
            description = ''
              How the background image should be made to fit inside an allocation.
            '';
          };
        };
        theme = {
          name = mkOption {
            type = types.str;
            default = "Adwaita";
            description = ''
              Name of the theme to use for regreet.
            '';
          };
          preferDark = mkEnableOption "GTK dark theme";
          package = mkPackageOption pkgs "gnome-themes-extra" { } // {
            description = ''
              The package that provides the theme given in the name option.
            '';
          };
        };
        cursorTheme = {
          name = mkOption {
            type = types.str;
            default = "Adwaita";
            description = ''
              Name of the cursor theme to use for regreet.
            '';
          };
          package = mkPackageOption pkgs "adwaita-icon-theme" { } // {
            description = ''
              The package that provides the cursor theme given in the name option.
            '';
          };
        };
        font = {
          name = mkOption {
            type = types.str;
            default = "Cantarell";
            description = ''
              Name of the font to use for regreet.
            '';
          };
          size = mkOption {
            type = types.ints.positive;
            default = 16;
            description = ''
              Size of the font to use for regreet.
            '';
          };
          package = mkPackageOption pkgs "cantarell-fonts" { } // {
            description = ''
              The package that provides the font given in the name option.
            '';
          };
        };
        iconTheme = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "Adwaita";
            description = ''
              Name of the icon theme to use for regreet.
            '';
          };
          package = lib.mkPackageOption pkgs "adwaita-icon-theme" { } // {
            description = ''
              The package that provides the icon theme given in the name option.
            '';
          };
        };
      };
      tuigreet = {
        enable = mkEnableOption "tuigreet";
        themeArgs = mkOption {
          type = types.attrs;
          default = { };
          description = ''
            Theme arguments passed to tuigreet in the Nix attribute set format.
          '';
        };
        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "--width 70" ];
          description = "Extra arguments passed to tuigreet.";
        };
      };
    };
    xwayland = {
      enable = mkEnableOption "xwayland-satellite" // {
        # Fcitx5 recommends enabling XWayland as a fallback for coordination reasons
        # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
        default = true;
      };
    };
    package = mkPackageOption pkgs "niri" { };
    packageWrapped = mkOption {
      type = types.package;
      default = cfg.package;
      readOnly = true;
      description = ''
        The final wrapped Niri package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) attrValues concatStringsSep;
      inherit (lib) getExe optionalAttrs;
      inherit (pkgs) writeText;
      inherit (murakumo.platforms) isAarch64;
      inherit (murakumo.generators) toKDL;
      inherit (murakumo.utils) countAttrs;
    in
    mkMerge [
      {
        assertions = [
          {
            assertion = (countAttrs (_: v: v.enable or false) cfg.greeter) == 1;
            message = "Exactly one greeter must be enabled at a time (Zero or multiple are not allowed)";
          }
        ];

        environment.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          XDG_CURRENT_DESKTOP = "niri";
          XDG_SESSION_DESKTOP = "niri";
          XDG_SESSION_TYPE = "wayland";
        }
        // optionalAttrs isAarch64 {
          # Force GTK4 (Regreet) to use the stable "New GL" driver instead of Vulkan
          # if the host's architecture is aarch64-linux. (e.g, nixos-apple-silicon)
          # Asahi's Vulkan driver (Honeykrisp) is still experimental and under
          # bleeding-edge development, causing some GTK4 apps to crash and triggering
          # an unrecoverable GPU freeze.
          # GSK_RENDERER = "ngl";
        };

        xdg.portal = {
          extraPortals = attrValues {
            inherit (pkgs) xdg-desktop-portal-gtk xdg-desktop-portal-gnome;
          };
          config = {
            common.default = [
              "gtk"
              "gnome"
            ];
            niri.default = [
              "gtk"
              "gnome"
            ];
          };
        };

        systemd.user.targets.niri-session = {
          unitConfig = {
            After = [ "graphical-session-pre.target" ];
            BindsTo = [ "graphical-session.target" ];
            Description = "Niri compositor session";
            Documentation = "man:systemd.special(7)";
            Wants = [ "graphical-session-pre.target" ];
          };
        };

        # Set the minimum config for the greetd login session.
        # This will be automatically merged with user-defined settings.
        # https://github.com/rharish101/ReGreet?tab=readme-ov-file#set-as-default-session
        yakumo.desktop.compositors.niri.loginSettings = {
          hotkey-overlay.skip-at-startup = { };
          binds = { };
          spawn-at-startup = [
            {
              _args = [
                "sh"
                "-c"
                "${getExe pkgs.regreet}; niri msg action quit --skip-confirmation"
              ];
            }
          ];
        };
      }
      (
        let
          inherit (builtins)
            isAttrs
            map
            mapAttrs
            ;
          inherit (lib) elem getName optional;
          inherit (pkgs) runCommand;
          inherit (murakumo.wrappers) mkAppWrapper;

          addBindSemicolons =
            binds:
            mapAttrs (
              _: bindDef:
              if !isAttrs bindDef then
                bindDef
              else
                mapAttrs (
                  action: def:
                  # Skip metadata props, apply terminator to actual action nodes.
                  if
                    elem action [
                      "_args"
                      "_props"
                      "_children"
                    ]
                  then
                    def
                  else
                    def // { _terminator = ";"; }
                ) bindDef
            ) binds;

          envVariables = concatStringsSep " " [
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
          ];

          systemdSessionCmds = concatStringsSep " " (
            map (f: "&& ${f}") [
              "systemctl --user start niri-session.target"
            ]
          );

          systemdInit = {
            _args = [
              "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${envVariables} ${systemdSessionCmds}"
            ];
          };

          finalSettings = cfg.settings // {
            binds = if cfg.settings ? binds then addBindSemicolons cfg.settings.binds else { };
            spawn-sh-at-startup = [ systemdInit ] ++ (cfg.settings.spawn-sh-at-startup or [ ]);
          };

          configKdl = writeText "config.kdl" (toKDL { } finalSettings);
          niriWrapped = mkAppWrapper {
            pkg = cfg.package;
            name = "${getName cfg.package}-${config.yakumo.user.name}";
            flags = [
              "--config"
              configKdl
            ];
          };
        in
        {
          yakumo.desktop.compositors.niri.packageWrapped = niriWrapped;
          yakumo.user.packages =
            attrValues { inherit (pkgs) ; } ++ optional cfg.xwayland.enable pkgs.xwayland-satellite;
          environment.systemPackages = [ niriWrapped ];

          # Expose the custom Niri wrapper to display managers so
          # we can see it on the login screen as a pickable session.
          services.displayManager.sessionPackages = [
            (runCommand "niri-yakumo-session"
              {
                # This satisfies the display manager's requirement by explicitly
                # declaring the base name of the .desktop file.
                # "Package, 'foo.desktop', did not specify any session names, as string,
                # in 'passthru.providedSessions'. This is required when used as
                # a session package".
                passthru.providedSessions = [ "niri-yakumo" ];
              }
              ''
                mkdir -p $out/share/wayland-sessions
                cat > $out/share/wayland-sessions/niri-yakumo.desktop <<EOF
                [Desktop Entry]
                Name=Niri (Yakumo ver.)
                Comment=A scrollable-tiling Wayland compositor
                Exec=${getExe niriWrapped}
                Type=Application
                DesktopNames=niri
                EOF
              ''
            )
          ];

          programs.regreet = mkIf (cfg.greeter == "regreet") (mkMerge [
          {
            enable = true;
            settings = {
              GTK.application_prefer_dark_theme = cfg.regreet.theme.preferDark;
              widget.clock = {
                format = "%a, %d %b %Y %I:%M";
              };
            };
            cursorTheme = {
              name = cfg.regreet.cursorTheme.name;
              package = cfg.regreet.cursorTheme.package;
            };
            font = {
              name = cfg.regreet.font.name;
              size = cfg.regreet.font.size;
              package = cfg.regreet.font.package;
            };
            iconTheme = {
              name = cfg.regreet.iconTheme.name;
              package = cfg.regreet.iconTheme.package;
            };
            theme = {
              name = cfg.regreet.theme.name;
              package = cfg.regreet.theme.package;
            };
          }
          (mkIf (cfg.regreet.background.path != null) {
            settings = {
              background = {
                path = cfg.regreet.background.path;
                fit = cfg.regreet.background.fit;
              };
            };
          })
        ]);

        services.greetd =
          let
            inherit (lib) optionalString;
            inherit (murakumo.generators) toTuigreetTheme;
            loginCfg = writeText "login-config.kdl" (toKDL { } cfg.loginSettings);
            tuigreetThemeStr = toTuigreetTheme cfg.greeter.tuigreet.themeArgs;
            tuigreetThemeArg = optionalString (tuigreetThemeStr != "") " --theme '${tuigreetThemeStr}'";
            tuigreetExtraArgs = optionalString (
              cfg.greeter.tuigreet.extraArgs != [ ]
            ) " ${concatStringsSep " " cfg.greeter.tuigreet.extraArgs}";
          in
          {
            enable = true;
            settings = {
              default_session = {
                command =
                  if (cfg.greeter == "regreet") then
                    # We don't use the wrapped Niri here.
                    # Wrap the greeter session in a localized DBus session to provide
                    # the app with an immediate DBus context.
                    "${pkgs.dbus}/bin/dbus-run-session ${getExe cfg.package} --config ${loginCfg}"
                  else
                    "${pkgs.tuigreet}/bin/tuigreet --time --remember${tuigreetThemeArg}${tuigreetExtraArgs} --cmd ${getExe niriWrapped}";
                user = "greeter";
              };
            };
          };
        }
      )
    ]
  );
}
