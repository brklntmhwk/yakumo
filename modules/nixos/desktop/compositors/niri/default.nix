{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib)
    literalExpression mkEnableOption mkIf mkMerge mkOption mkPackageOption
    types;
  cfg = config.yakumo.desktop.compositors.niri;
  yamlFormat = pkgs.formats.yaml { };
in {
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
        input.keyboard.xkb._children = [{
          layout._args = [ "us" ];
          options._args = [ "terminate:ctrl_alt_bksp" ];
        }];
        input.focus-follows-mouse._props.max-scroll-amount = "0%";
      };
    };
    # https://github.com/NixOS/nixpkgs/commit/ab65220a1af24cc46a67021e624fce3f4c87ebfa
    regreet = {
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
          type = types.enum [ "Contain" "Cover" "Fill" "ScaleDown" ];
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

  config = mkIf cfg.enable (let inherit (builtins) attrValues;
  in mkMerge [
    {
      environment.sessionVariables = {
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
      };

      xdg.portal = {
        extraPortals = attrValues {
          inherit (pkgs) xdg-desktop-portal-gtk xdg-desktop-portal-gnome;
        };
        config = {
          common.default = [ "gtk" "gnome" ];
          niri.default = [ "gtk" "gnome" ];
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
    }
    (let
      inherit (lib) getName optional mapAttrs isAttrs;
      inherit (pkgs) writeText;
      inherit (murakumo.wrappers) mkAppWrapper;
      inherit (murakumo.generators) toKDL;

      addBindSemicolons = binds:
        mapAttrs (key: bindDef:
          if !isAttrs bindDef then
            bindDef
          else
            mapAttrs (action: def:
              # Skip metadata props, apply terminator to actual action nodes
              if elem action [ "_args" "_props" "_children" ] then
                def
              else
                def // { _terminator = ";"; }) bindDef) binds;

      finalSettings = cfg.settings // {
        binds = if cfg.settings ? binds then
          addBindSemicolons cfg.settings.binds
        else
          { };
      };

      configKdl = writeText "config.kdl" (toKDL { } finalSettings);
      niriWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [ "--config" configKdl ];
      };
    in {
      yakumo.desktop.compositors.niri.packageWrapped = niriWrapped;
      yakumo.user.packages = attrValues { inherit (pkgs) ; }
        ++ optional cfg.xwayland.enable pkgs.xwayland-satellite;
      environment.systemPackages = [ niriWrapped ];
    })
    (let regreetCfg = cfg.regreet;
    in {
      programs.regreet = mkMerge [
        {
          enable = true;
          settings = {
            GTK.application_prefer_dark_theme = regreetCfg.theme.preferDark;
            widget.clock = { format = "%a, %d %b %Y %I:%M"; };
          };
          cursorTheme = {
            name = regreetCfg.cursorTheme.name;
            package = regreetCfg.cursorTheme.package;
          };
          font = {
            name = regreetCfg.font.name;
            size = regreetCfg.font.size;
            package = regreetCfg.font.package;
          };
          iconTheme = {
            name = regreetCfg.iconTheme.name;
            package = regreetCfg.iconTheme.package;
          };
          theme = {
            name = regreetCfg.theme.name;
            package = regreetCfg.theme.package;
          };
        }
        (mkIf (regreetCfg.background.path != null) {
          settings = {
            background = {
              path = regreetCfg.background.path;
              fit = regreetCfg.background.fit;
            };
          };
        })
      ];

      # https://github.com/rharish101/ReGreet?tab=readme-ov-file#set-as-default-session
      services.greetd = let
        inherit (lib) getExe;

        loginCfg = pkgs.writeText "login-config.kdl" ''
          hotkey-overlay {
              skip-at-startup
          }
          binds {

          }
          spawn-at-startup "sh" "-c" "${
            getExe pkgs.greetd.regreet
          }; niri msg action quit --skip-confirmation"
        '';
      in {
        enable = true;
        settings = {
          default_session = {
            # We don't use the wrapped Niri here.
            command = "${getExe cfg.package} --config ${loginCfg}";
            user = "greeter";
          };
        };
      };
    })
  ]);
}
