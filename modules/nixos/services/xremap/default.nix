# Based on:
# https://github.com/xremap/nix-flake

# This is a simpler and more "for me" version of the official Xremap NixOS module:
# - Strips away extra module options that exist only for backward compatibility and flexibility.
# - Removes the system service layer, covering the user service layer only.
{
  # inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkPackageOption
    types
    ;
  cfg = config.yakumo.services.xremap;
  compositorsCfg = config.yakumo.desktop.compositors;
  yamlFormat = pkgs.formats.yaml { };
in
{
  # We migrated to packaging it on our own and don't use the official
  # NixOS module anymore.
  # imports = [ inputs.xremap.nixosModules.default ];

  options.yakumo.services.xremap = {
    enable = mkEnableOption "xremap";
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      description = ''
        Xremap configuration in Nix-representable YAML format.
        For the valid setting options, see:
        https://github.com/xremap/xremap?tab=readme-ov-file#Configuration
      '';
      example = {
        modmap = [
          {
            name = "Global";
            remap = {
              CapsLock = "Esc";
              Ctrl_L = "Esc";
            };
          }
        ];
        keymap = [
          {
            name = "Default (Nocturn, etc.)";
            application = {
              not = [
                "Google-chrome"
                "Slack"
                "Gnome-terminal"
                "jetbrains-idea"
              ];
            };
            remap = {
              "C-b" = "left";
              "C-f" = "right";
            };
          }
        ];
      };
    };
    deviceNames = mkOption {
      type = types.nullOr (types.listOf types.nonEmptyStr);
      default = null;
      description = "List of devices to remap.";
    };
    debug = mkEnableOption "xremap to run with RUST_LOG=debug";
    mouse = mkEnableOption "xremap to watch mice";
    watch = mkEnableOption "xremap to watch new devices";
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--completions zsh" ];
      description = "Extra arguments passed to xremap.";
    };
    package = mkOption {
      type = types.package;
      default =
        if compositorsCfg.hyprland.enable then
          pkgs.xremap.override {
            withVariant = "hyprland";
          }
        else if compositorsCfg.niri.enable then
          pkgs.xremap-niri
        else
          pkgs.xremap;
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) concatStringsSep;
      inherit (lib)
        flatten
        getExe
        optional
        optionalAttrs
        singleton
        ;

      # https://github.com/xremap/nix-flake/blob/9a2224aa01a3c86e94b398c33329c8ff6496dc5d/lib/default.nix
      mkExecStart =
        configFile:
        let
          mkDeviceString = x: "--device '${x}'";
        in
        concatStringsSep " " (
          flatten (
            singleton "${getExe cfg.package}"
            ++ (if cfg.deviceNames != null then map mkDeviceString cfg.deviceNames else [ ])
            ++ optional cfg.watch "--watch"
            ++ optional cfg.mouse "--mouse"
            ++ cfg.extraArgs
            ++ singleton configFile
          )
        );
    in
    {
      # https://github.com/xremap/nix-flake/blob/9a2224aa01a3c86e94b398c33329c8ff6496dc5d/modules/user-service.nix
      hardware.uinput.enable = true;
      # Uinput group owns the /uinput.
      users.groups.uinput.members = [ cfg.userName ];
      # Allow access to /dev/input.
      users.groups.input.members = [ cfg.userName ];

      systemd.user.services.xremap = {
        description = "xremap user service.";
        path = [ cfg.package ];
        serviceConfig = mkMerge [
          {
            KeyringMode = "private";
            SystemCallArchitectures = [ "native" ];
            RestrictRealtime = true;
            ProtectSystem = true;
            SystemCallFilter = map (x: "~@${x}") [
              "clock"
              "debug"
              "module"
              "reboot"
              "swap"
              "cpu-emulation"
              "obsolete"
              # NOTE: These two make the spawned processes drop cores.
              # "privileged"
              # "resources"
            ];
            LockPersonality = true;
            UMask = "077";
            RestrictAddressFamilies = "AF_UNIX";
            ExecStart = mkExecStart cfg.settings;
          }
          (optionalAttrs cfg.debug { Environment = [ "RUST_LOG=debug" ]; })
        ];
        wantedBy = [ "graphical-session.target" ];
      };

      # services.xremap = mkMerge [
      #   (mkIf (compositorsCfg.hyprland.enable) { withHypr = true; })
      #   (mkIf (compositorsCfg.niri.enable) { withNiri = true; })
      # ];
    }
  );
}
