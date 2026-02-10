{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib)
    elem getExe literalExpression mkEnableOption mkIf mkMerge mkOption
    mkPackageOption types;
  cfg = config.yakumo.programs.television;
  tomlFormat = pkgs.formats.toml { };
  channels = [ "files" "nix-search-tv" ];
in {
  options.yakumo.programs.television = {
    enable = mkEnableOption "television";
    channels = mkOption {
      type = types.listOf (types.enum channels);
      default = [ ];
      description = "Channels cabled to Television.";
    };
    # https://github.com/nix-community/home-manager/commit/22b326b42bf42973d5e4fe1044591fb459e6aeac
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Television configuraion in Nix-representable TOML format.
        For the full options configurable, see:
        https://alexpasmantier.github.io/television/docs/Users/configuration
      '';
      example = literalExpression ''
        {
          tick_rate = 50;
          ui = {
            use_nerd_font_icons = true;
            ui_scale = 120;
            show_preview_panel = false;
          };
          keybindings = {
            quit = [ "esc" "ctrl-c" ];
          };
        }
      '';
    };
    channelSettings = lib.mkOption {
      type = lib.types.attrsOf tomlFormat.type;
      default = { };
      description = ''
        Channel configurations for Television in Nix-representable TOML format.
        For the full options configurable, see:
        https://alexpasmantier.github.io/television/docs/Users/channels
      '';
      example = {
        git-diff = {
          metadata = {
            name = "git-diff";
            description = "A channel to select files from git diff commands.";
            requirements = [ "git" ];
          };
          source = { command = "git diff --name-only HEAD"; };
          preview = { command = "git diff HEAD --color=always -- '{}'"; };
        };
        git-log = {
          metadata = {
            name = "git-log";
            description = "A channel to select from git log entries.";
            requirements = [ "git" ];
          };
          source = {
            command = ''
              git log --oneline --date=short --pretty="format:%h %s %an %cd" "$@"'';
            output = "{split: :0}";
          };
          preview = {
            command = "git show -p --stat --pretty=fuller --color=always '{0}'";
          };
        };
      };
    };
    package = mkPackageOption pkgs "television" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Television package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (elem "nix-search-tv" cfg.channels) {
      # https://github.com/nix-community/home-manager/commit/b7ee8deefca4f88be521077b2f6975618c7e0ab6
      yakumo.programs.television.channelSettings.nix-search-tv =
        let path = getExe pkgs.nix-search-tv;
        in {
          metadata = {
            name = "nix-search-tv";
            description = "A channel to search Nix options and packages.";
          };
          source.command = "${path} print";
          preview.command = ''${path} preview "{}"'';
        };
    })
    (mkIf (elem "files" cfg.channels) {
      yakumo.programs.television.channelSettings.files = let
        batPath = getExe pkgs.bat;
        fdPath = getExe pkgs.fd;
      in {
        metadata = {
          name = "files";
          description = "A channel to select files and directories.";
        };
        source.command = "${fdPath} -t f";
        preview = {
          command = ''${batPath} -n --color=always "{}"'';
          env = { BAT_THEME = "ansi"; };
        };
        keybindings = { shortcut = "f1"; };
      };
    })
    (let
      inherit (builtins) attrValues;
      inherit (lib) concatLines getName mapAttrsToList optional optionals;
      inherit (pkgs) runCommand;
      inherit (murakumo.wrappers) mkAppWrapper;

      configToml = tomlFormat.generate "config.toml" cfg.settings;
      # Mimic the directory structure Television expects.
      configDir = runCommand "television-config" { } ''
        mkdir -p $out/channels

        # Link the main config file.
        ln -s ${configToml} $out/config.toml

        # Loop through channels and link them into the 'channels' sub-directory.
        ${concatLines (mapAttrsToList (name: channelCfg: ''
          ln -s ${
            tomlFormat.generate "${name}.toml" channelCfg
          } $out/channels/${name}.toml
        '') cfg.channelSettings)}
      '';
      televisionWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        env = { TELEVISION_CONFIG = "${configDir}"; };
      };
    in {
      yakumo.programs.television.packageWrapped = televisionWrapped;
      yakumo.user.packages = [ televisionWrapped ]
        ++ optional (elem "nix-search-tv" cfg.channels) pkgs.nix-search-tv
        ++ optionals (elem "files" cfg.channels)
        (attrValues { inherit (pkgs) bat fd; });
    })
  ]);
}
