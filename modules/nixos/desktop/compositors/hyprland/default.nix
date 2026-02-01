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
  inherit (murakumo.configs) genFinalPackage;
  cfg = config.yakumo.desktop.compositors.hyprland;
in
{
  options.yakumo.desktop.compositors.hyprland = {
    enable = mkEnableOption "hyprland";
    # https://github.com/nix-community/home-manager/commit/ee5673246de0254186e469935909e821b8f4ec15
    settings = mkOption {
      type =
        let
          valType =
            types.nullOr (
              types.oneOf [
                types.bool
                types.float
                types.int
                types.path
                types.str
                (types.attrsOf valType)
                (types.listOf valType)
              ]
            )
            // {
              description = "Hyprland configuration values in Nix-representable Hyprconf format.";
            };
        in
        valType;
      default = { };
      description = ''
        Hyprland configuraion in Nix-representable Hyprconf format.
      '';
      example = literalExpression ''
        {
          decoration = {
            shadow_offset = "0 5";
            "col.shadow" = "rgba(00000099)";
          };

          "$mod" = "SUPER";

          bindm = [
            # mouse movements
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
            "$mod ALT, mouse:272, resizewindow"
          ];
        }
      '';
    };
    # Submaps must be taken out of the 'settings' block because they rely on
    # strict imperative line ordering while attribute sets are inherently
    # unordered in Nix.
    submaps = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              settings = lib.mkOption {
                type = (types.attrsOf (types.listOf types.str)) // {
                  description = "Hyprland binds";
                };
                default = { };
                description = ''
                  Hyprland binds to be put in the submap
                '';
                example = literalExpression ''
                  {
                    binde = [
                     ", right, resizeactive, 10 0"
                     ", left, resizeactive, -10 0"
                     ", up, resizeactive, 0 -10"
                     ", down, resizeactive, 0 10"
                    ];

                    bind = [
                      ", escape, submap, reset"
                    ];
                  }
                '';
              };
            };
          }
        )
      );
    };
    xwayland = {
      enable = mkEnableOption "XWayland" // {
        # Fcitx5 recommends enabling XWayland as a fallback for coordination reasons
        # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
        default = true;
      };
    };
    # https://github.com/NixOS/nixpkgs/commit/48da44a4810038833578630cb10f135a38eefb1f
    package =
      mkPackageOption pkgs "hyprland" {
        extraDescription = ''
          If the package is not overridable with `enableXWayland`, then the module option
          {option}`xwayland` will have no effect.
        '';
      }
      // {
        apply =
          p:
          genFinalPackage p {
            enableXWayland = cfg.xwayland.enable;
          };
      };
    cursorPackage = mkPackageOption pkgs "rose-pine-hyprcursor" { };
    packageWrapped = mkOption {
      type = types.package;
      default = cfg.package;
      readOnly = true;
      description = ''
        The final wrapped Hyprland package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) attrValues hasAttr;
    in
    mkMerge [
      {
        assertions = [
          # https://github.com/nix-community/home-manager/commit/1ecfd8e5626b27a9610f468be32cd6a7011f56a0
          {
            assertion = !hasAttr "reset" cfg.submaps;
            message = "Submaps can't be named 'reset'. The name 'reset' is reserved in order to have a way to switch to the default submap; as if 'reset' was its name.";
          }
        ];

        environment.sessionVariables = {
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          XDG_CURRENT_DESKTOP = "hyprland";
          XDG_SESSION_DESKTOP = "hyprland";
          XDG_SESSION_TYPE = "wayland";
        };

        xdg.portal = {
          extraPortals = attrValues {
            inherit (pkgs)
              xdg-desktop-portal-gtk
              xdg-desktop-portal-hyprland
              ;
          };
          config = {
            common.default = [
              "gtk"
              "hyprland"
            ];
            hyprland.default = [
              "gtk"
              "hyprland"
            ];
          };
        };

        systemd.user.targets.hyprland-session = {
          unitConfig = {
            After = [ "graphical-session-pre.target" ];
            BindsTo = [ "graphical-session.target" ];
            Description = "Hyprland compositor session";
            Documentation = "man:systemd.special(7)";
            Wants = [ "graphical-session-pre.target" ];
          };
        };

        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              # Don't use Regreet with Hyprland. That combo seems buggy as in:
              # https://www.reddit.com/r/NixOS/comments/14rhsnu/regreet_greeter_for_greetd_doesnt_show_a_session/
              # Tuigreet would be more stable.
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
              user = "greeter";
            };
          };
        };
      }
      (
        let
          inherit (lib)
            concatMapAttrsStringSep
            getName
            optional
            optionalString
            ;
          inherit (pkgs) writeText;
          inherit (murakumo.wrappers) mkAppWrapper;
          inherit (murakumo.generators) toHyprconf;

          mkSubMap = name: attrs: ''
            submap = ${name}
            ${
              toHyprconf {
                attrs = attrs.settings;
                indentLevel = 0;
              }
            }submap = reset
          '';
          submapsToHyprConf = concatMapAttrsStringSep "\n" mkSubMap;
          hyprlandConf = writeText "hyprland.conf" (
            optionalString (cfg.settings != { }) (toHyprconf {
              attrs = cfg.settings;
            })
            + (optionalString (cfg.submaps != { }) (submapsToHyprConf cfg.submaps))
          );

          hyprlandWrapped = mkAppWrapper {
            pkg = cfg.package;
            name = "${getName cfg.package}-${config.yakumo.user.name}";
            flags = [
              "--config"
              hyprlandConf
            ];
          };
        in
        {
          yakumo.desktop.compositors.hyprland.packageWrapped = hyprlandWrapped;
          yakumo.user.packages =
            attrValues {
              inherit (pkgs)
                grimblast # Screenshot util from Hypr ecosystem.
                hyprpicker # Color picker from Hypr ecosystem.
                ;
            }
            ++ optional cfg.xwayland.enable pkgs.xwayland;
          environment.systemPackages = [ hyprlandWrapped ];
        }
      )
    ]
  );
}
