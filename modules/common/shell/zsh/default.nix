{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    attrNames
    literalExpression
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.shell.zsh;
  bindkeyCommands = {
    emacs = "bindkey -e";
    viins = "bindkey -v";
    vicmd = "bindkey -a";
  };
  # https://github.com/nix-community/home-manager/commit/1b0efe3d335f452595512c7b275e5dddfbfb28a5
  syntaxHighlightingSubmodule = types.submodule {
    options = {
      highlighters = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "brackets"
          "cursor"
          "main"
          "pattern"
        ];
        description = ''
          List of highlighters to enable.
          For the exhaustive list of highlighters, see:
          https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
        '';
      };
      patterns = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          "rm -rf *" = "fg=white,bold,bg=red";
        };
        description = ''
          Custom syntax highlighting for user-defined patterns.
          For the details of pattern configurations, see:
          https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/pattern.md>
        '';
      };
      styles = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          comment = "fg=#6e6a86,italic";
          alias = "fg=#9ccfd8,bold";
        };
        description = ''
          Custom styles for syntax highlighting contexts.
          For the details of highlighter style options, see:
          https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md
        '';
      };
      package = lib.mkPackageOption pkgs "zsh-syntax-highlighting" { };
    };
  };
in
{
  options.yakumo.shell.zsh = {
    enable = mkEnableOption "zsh";
    defaultShell = mkEnableOption "zsh as global default shell";
    # https://github.com/nix-community/home-manager/commit/a4383075af86c46a812f982b270023d9e943f898
    defaultKeymap = mkOption {
      type = types.nullOr (types.enum (attrNames bindkeyCommands));
      default = null;
      example = "emacs";
      description = "The default base keymap to use.";
    };
    # https://github.com/nix-community/home-manager/commit/9b76feafd02c84935ca3dea671057ca28b08131f
    setOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Zsh options as in setopt.
        To unset an option, prefix it with "NO_".
        For more details, see {manpage}`zshoptions(1)`.
      '';
      example = [
        "EXTENDED_HISTORY"
        "RM_STAR_WAIT"
        "NO_BEEP"
      ];
    };
    shellAliases = mkOption {
      type = types.attrsOf (types.nullOr (types.either types.str types.path));
      default = { };
      description = ''
        Set of aliases for zsh shell.
      '';
      example = literalExpression ''
        {
          ll = "ls -l";
          ".." = "cd ..";
        }
      '';
    };
    abbreviations = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Set of Zsh abbreviations managed by zsh-abbr.";
      example = {
        gco = "git checkout";
        dc = "docker compose";
      };
    };
    syntaxHighlighting = mkOption {
      type = syntaxHighlightingSubmodule;
      default = { };
      description = "Set of options as for zsh-syntax-highlighting.";
    };
    initExtraFirst = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run at the very beginning of .zshrc coupled with setting environment variables.
      '';
    };
    initExtraBeforeCompInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run before 'compinit' is called.
        Use this to configure completion styles.
      '';
      example = ''
        zstyle ':completion:*' menu true
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      '';
    };
    initExtraLast = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run at the end of .zshrc (Aliases, Prompts, Tools, etc.).
      '';
      example = ''
        function mkcd() { mkdir -p "$1" && cd "$1"; }
      '';
    };
    # https://github.com/nix-community/home-manager/commit/196487c54f58f237fade6b85dfd57f097c8b5581
    plugins = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of the plugin.";
            };
            src = mkOption {
              type = types.path;
              description = "Path to the plugin folder (usually a package).";
            };
            file = mkOption {
              type = types.str;
              description = "Relative path to the file to source.";
            };
          };
        }
      );
      default = [ ];
      description = "List of Zsh plugins to install and source.";
      example = literalExpression ''
        [
          {
            name = "zsh-abbr";
            src = pkgs.zsh-abbr;
            file = "share/zsh/zsh-abbr/zsh-abbr.zsh";
          }
        ]
      '';
    };
    package = mkPackageOption pkgs "zsh" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Zsh package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (
      let
        inherit (lib) any;
        pluginMissingMsg = plugin: opt: ''
          The '${plugin}' plugin must be installed via the 'plugins' option simultaneously to use the '${opt}' option.
        '';
      in
      {
        assertions = [
          {
            assertion = (cfg.abbreviations != { }) -> (any (p: p.name == "zsh-abbr") cfg.plugins);
            message = pluginMissingMsg "zsh-abbr" "abbreviations";
          }
          {
            assertion =
              (
                cfg.syntaxHighlighting.styles != { }
                || cfg.syntaxHighlighting.highlighters != [ ]
                || cfg.syntaxHighlighting.patterns != { }
              )
              -> (any (p: p.name == "zsh-syntax-highlighting") cfg.plugins);
            message = pluginMissingMsg "zsh-syntax-highlighting" "syntaxHighlighting";
          }
        ];
      }
    )
    (
      let
        inherit (builtins) concatStringsSep getAttr map;
        inherit (lib)
          escapeShellArg
          getName
          mapAttrsToList
          optionalString
          ;
        inherit (pkgs) writeTextDir;
        inherit (murakumo.wrappers) mkAppWrapper;

        optsStr = concatStringsSep "\n" (map (opt: "setopt ${opt}") cfg.setOptions);
        keymapStr = optionalString (cfg.defaultKeymap != null) bindkeyCommands.${cfg.defaultKeymap};
        pluginsStr = concatStringsSep "\n" (
          map (plugin: ''
            # Plugin: ${plugin.name}
            source "${plugin.src}/${plugin.file}"
          '') cfg.plugins
        );
        pluginPackages = map (p: p.src) cfg.plugins;
        # https://github.com/nix-community/home-manager/commit/ad487d3863e94ac839b2e1e451197ab5a4aafd1b
        aliases = concatStringsSep "\n" (
          mapAttrsToList (k: v: "alias -- ${escapeShellArg k}=${escapeShellArg v}") cfg.shellAliases
        );
        # Use '--session' so it doesn't try to write to a read-only file.
        # Use '--force' to overwrite any existing ones without prompt.
        abbrCmds = concatStringsSep "\n" (
          mapAttrsToList (
            k: v: "abbr --session --force ${escapeShellArg k}=${escapeShellArg v}"
          ) cfg.abbreviations
        );
        highlightersCmd = "ZSH_HIGHLIGHT_HIGHLIGHTERS+=(${concatStringsSep " " (map escapeShellArg cfg.syntaxHighlighting.highlighters)})";
        stylesCmd = concatStringsSep "\n" (
          mapAttrsToList (
            k: v: "ZSH_HIGHLIGHT_STYLES[${escapeShellArg k}]=${escapeShellArg v}"
          ) cfg.syntaxHighlighting.styles
        );
        patternsCmd = concatStringsSep "\n" (
          mapAttrsToList (
            k: v: "ZSH_HIGHLIGHT_PATTERNS+=(${escapeShellArg k} ${escapeShellArg v})"
          ) cfg.syntaxHighlighting.patterns
        );

        zshConfigDir = writeTextDir ".zshrc" ''
          ${optionalString (cfg.initExtraFirst != "") ''
            # User hook: First
            ${cfg.initExtraFirst}
          ''}

          ${optionalString (cfg.setOptions != [ ]) ''
            # User-defined options
            ${optsStr}
          ''}

          ${optionalString (cfg.defaultKeymap != null) ''
            # Default keymap
            ${keymapStr}
          ''}

          ${optionalString (cfg.initExtraBeforeCompInit != "") ''
            # User hook: Before compinit
            ${cfg.initExtraBeforeCompInit}
          ''}

          # Completions
          # Initialize completions and store dump in cache.
          autoload -Uz compinit

          # Versioned cache path
          _comp_path="''${XDG_CACHE_HOME}/zsh/zcompdump-''${ZSH_VERSION}"

          # Use -C (skip check) to speed up init, but check if the file exists first.
          # If it doesn't exist, regular 'compinit' runs and generates it.
          if [[ -f "''${_comp_path}" ]]; then
             compinit -u -C -d "''${_comp_path}"
          else
             compinit -u -d "''${_comp_path}"
          fi

          # Compile to .zwc for speed if the .zwc file is missing or older.
          if [[ ! -f "''${_comp_path}.zwc" || "''${_comp_path}" -nt "''${_comp_path}.zwc" ]]; then
             zcompile "''${_comp_path}"
          fi

          ${optionalString (cfg.shellAliases != { }) ''
            # User-defined shell aliases
            ${aliases}
          ''}

          ${optionalString (cfg.plugins != [ ]) ''
            # Plugins
            ${pluginsStr}
          ''}

          ${optionalString (cfg.abbreviations != { }) ''
            # Abbreviations
            if (( $+commands[abbr] )); then
              ${abbrCmds}
            fi
          ''}

          ${optionalString
            (
              cfg.syntaxHighlighting.highlighters != [ ]
              || cfg.syntaxHighlighting.styles != { }
              || cfg.syntaxHighlighting.patterns != { }
            )
            ''
              # Syntax Highlighting
              if (( $+ZSH_HIGHLIGHT_STYLES )); then
                ${highlightersCmd}
                ${stylesCmd}
                ${patternsCmd}
              fi
            ''
          }

          ${optionalString (cfg.initExtraLast != "") ''
            # User hook: Last
            ${cfg.initExtraLast}
          ''}
        '';
        zshWrapped =
          (mkAppWrapper {
            pkg = cfg.package;
            name = "${getName cfg.package}-${config.yakumo.user.name}";
            env = {
              ZDOTDIR = zshConfigDir;
            };
          }).overrideAttrs
            (_: {
              passthru = {
                shellPath = "/bin/zsh";
              };
            });
      in
      {
        yakumo.shell.zsh.packageWrapped = zshWrapped;
        yakumo.user.packages = [ zshWrapped ] ++ pluginPackages;

        users.defaultUserShell = mkIf cfg.defaultShell zshWrapped;

        # Add the wrapped Zsh to a permissible login shell list
        # if the 'defaultUserShell' is set to true.
        environment.shells = mkIf cfg.defaultUserShell [ zshWrapped ];
      }
    )
  ]);
}
