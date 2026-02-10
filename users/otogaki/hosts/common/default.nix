{ config, lib, pkgs, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) catAttrs;
  inherit (theme) cursorThemes fonts;
  theme = import ../../themes/modus-vivendi-tinted pkgs;
in {
  imports = [
    ../../../common # Common configs among users
  ];

  yakumo.user = {
    name = "otogaki";
    description = "Ohma Togaki";
    hashedPasswordFile = config.sops.secrets.login_password_otogaki.path;
    # The value of 'config.users.defaultUserShell' will be set here for normal users.
    # For the detailed implementation, see:
    # https://github.com/NixOS/nixpkgs/commit/a323d146b7be3bc066b4ec74db72888ea32792fb
    # shell = config.yakumo.shell.default;
    packages = catAttrs "package" (attrValues cursorThemes);
  };

  yakumo.shell = {
    zsh = {
      enable = true;
      defaultShell = true;
      defaultKeymap = "emacs";
      setOptions = [
        "APPEND_HISTORY" # Append to the history file rather than overwriting.
        "AUTO_PUSHD" # 'cd' pushes the old directory onto a stack.
        "HIST_IGNORE_SPACE" # Don't record commands starting with a space.
        "HIST_IGNORE_DUPS" # Don't record an entry if it's the same as the previous one.
        "NO_BEEP" # Silence the bell on errors.
        "PUSHD_IGNORE_DUPS" # Don't push the same directory twice.
        "PUSHD_SILENT" # 'pushd' and 'popd' don't print the directory stack.
        "SHARE_HISTORY"
      ];
      shellAliases = { ".." = "cd .."; };
      abbreviations = {
        bctl = "bluetoothctl";
        jctl = "journalctl";
        nctl = "networkctl";
        snctl = "sudo networkctl";
        sctl = "systemctl";
        usctl = "systemctl --user";
        usctlr = "systemctl --user restart";
        usctls = "systemctl --user status";
        ssctl = "sudo systemctl";
        ssctlr = "sudo systemctl restart";
        ssctls = "sudo systemctl status";
        ga = "git add";
        gc = "git commit";
        gco = "git checkout";
        gl = "git log";
        gp = "git push";
        ls = "eza";
        lsl = "eza -al --accessed --binary --group --header --modified";
        lsla = "lsl --sort=accessed";
        lslm = "lsl --sort=modified";
        mkdir = "mkdir -pv";
      };
      syntaxHighlighting = {
        highlighters = [ ];
        styles = { };
        patterns = { };
      };
      initExtraFirst = ''
        export HISTFILE=""
        export HISTSIZE=10000
        export SAVEHIST=10000
      '';
      initExtraBeforeCompInit = ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      '';
      plugins = [
        {
          name = "zsh-abbr";
          src = pkgs.zsh-abbr;
          file = "share/zsh/zsh-abbr/zsh-abbr.zsh";
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
          file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
        }
      ];
    };
    starship = {
      enable = true;
      settings = import ../../configs/starship { inherit theme; };
    };
    zoxide = { enable = true; };
  };

  yakumo.ai = {
    agents = {
      claude-code = { enable = true; };
      gemini-cli = { enable = true; };
    };
    mcp = {
      enable = true;
      filesystem = {
        enable = true;
        paths = [ "${config.yakumo.user.home}/projects" ];
      };
      github.enable = true;
    };
  };

  yakumo.programs = {
    cli-utils.enable = true;
    tui-utils.enable = true;
    bottom = {
      enable = true;
      settings = import ../../configs/bottom { inherit theme; };
    };
    git = {
      enable = true;
      config = import ../../configs/git { inherit config; };
    };
    television = {
      enable = true;
      channels = [ "files" "nix-search-tv" ];
      settings = import ../../configs/television { inherit theme; };
    };
  };

  # When it comes to fonts, this is the only option common between
  # NixOS and Nix Darwin.
  fonts.packages = catAttrs "package" (attrValues fonts);
}
