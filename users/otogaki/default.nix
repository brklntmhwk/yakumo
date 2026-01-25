{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) catAttrs;
  theme = import ./themes/modus-vivendi-tinted;
in
{
  yakumo.user = {
    name = "otokagi";
    description = "Ohma Togaki";
    extraGroups = [
      "video"
      "networkmanager"
      "wheel"
    ];
    hashedPasswordFile = config.sops.secrets.login_password_otogaki.path;
    # The value of 'config.users.defaultUserShell' will be set here for normal users.
    # For the detailed implementation, see:
    # https://github.com/NixOS/nixpkgs/commit/a323d146b7be3bc066b4ec74db72888ea32792fb
    # shell = config.yakumo.shell.default;
    packages = attrValues {
      inherit (pkgs)
        ;
    };
  };

  yakumo.system = {
    i18n = {
      inputMethod = {
        enable = true;
        fcitx5 = {
          enable = true;
          extraAddons = [ ];
          quickPhrase = { };
        };
      };
    };
  };

  yakumo.desktop = {
    enable = true;
    media = {
      modules = [
        "music"
        "video"
      ];
    };
    compositors = {
      niri = {
        enable = true;
        xwayland = true;
        settings = import ./configs/niri { inherit theme; };
        regreet = {
          theme = {
            name = theme.loginThemes.adwaita.name;
            package = theme.loginThemes.adwaita.package;
          };
          cursorTheme = {
            name = theme.cursorThemes.adwaita.name;
            package = theme.cursorThemes.adwaita.package;
          };
          font = {
            name = theme.fonts.moralerspaceHw.name;
            package = theme.fonts.moralerspaceHw.package;
            size = 16;
          };
        };
      };
    };
    daemons = {
      mako = {
        enable = true;
        settings = import ./configs/mako { inherit theme; };
      };
      swayidle = {
        enable = true;
        settings = import ./configs/swayidle { };
      };
    };
    lockers = {
      swaylock = {
        enable = true;
        settings = import ./configs/swaylock { inherit theme; };
      };
    };
    terms = {
      wezterm = {
        enable = true;
        settings = import ./configs/wezterm { inherit theme; };
      };
    };
    apps = {
      nyxt = {
        enable = true;
        config = import ./configs/nyxt/init.lisp { };
      };
      thunar = {
        enable = true;
      };
      waybar = {
        enable = true;
        settings = import ./configs/waybar { };
        style = import ./configs/waybar/style.nix { inherit theme; };
      };
      wofi = {
        enable = true;
        settings = import ./configs/wofi { };
        style = import ./configs/wofi/style.nix { inherit theme; };
      };
    };
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
      shellAliases = {
        ".." = "cd ..";
      };
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
        highlighters = [];
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
          file = "share/zsh-abbr/zsh-abbr.zsh";
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
      settings = import ./configs/starship { inherit theme; };
    };
    zoxide = {
      enable = true;
    };
  };

  yakumo.editors = {
    emacs = {
      enable = true;
      ametsuchi.enable = true;
    };
  };

  yakumo.ai = {
    agents = {
      claude-code = {
        enable = true;
      };
      gemini-cli = {
        enable = true;
      };
    };
    mcp = {
      enable = true;
      filesystem.enable = true;
      github.enable = true;
    };
  };

  yakumo.programs = {
    cli-utils.enable = true;
    tui-utils.enable = true;
    bottom = {
      enable = true;
      settings = import ./configs/bottom { inherit theme; };
    };
    git = {
      enable = true;
      config = import ./configs/git { inherit theme; };
    };
    television = {
      enable = true;
      channels = [
        "files"
        "nix-search-tv"
      ];
      settings = import ./configs/television { inherit theme; };
    };
    wthrr = {
      enable = true;
      settings = import ./configs/wthrr { };
    };
  };

  yakumo.services = {
    xremap = {
      enable = true;
      userName = config.yakumo.user.name;
      serviceMode = "user";
      config = import ./configs/xremap { };
    };
  };

  programs.yazi = {
    enable = true;
    settings = import ./configs/yazi { inherit theme; };
  };

  time.timeZone = "Asia/Tokyo";

  fonts = {
    packages =
      attrValues {
        inherit (pkgs)
          ;
      }
      ++ (catAttrs "package" (attrValues theme.fonts));
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [ theme.fonts.notoCjkSerif.name ];
        sansSerif = [ theme.fonts.notoCjkSans.name ];
        monospace = [ theme.fonts.hackgenNf.name ];
        emoji = [ theme.fonts.notoEmoji.name ];
      };
    };
  };

  environment.systemPackages = (
    let
      inherit (pkgs) hunspellDicts;
    in
    attrValues {
      # Dictionaries for multiple languages
      inherit (hunspellDicts)
        en-us
        en-gb-ise
        es-any
        ;
      inherit (pkgs)
        ;
    }
  );
}
