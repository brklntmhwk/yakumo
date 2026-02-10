# NOTE: Exceptionally adopting the mutable user config directory using Nix-maid.
{ inputs, config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
  cfg = config.yakumo.desktop.apps.browsers.nyxt;
in {
  imports = [ inputs.nix-maid.nixosModules.default ];

  options.yakumo.desktop.apps.browsers.nyxt = {
    enable = mkEnableOption "nyxt";
    # https://github.com/nix-community/home-manager/commit/2835e8ba0ad99ba86d4a5e497a962ec9fa35e48f
    config = mkOption {
      type = types.either types.lines types.path;
      default = "";
      description = ''
        Nyxt configuration written in Common Lisp.
      '';
      example = ''
        (in-package #:nyxt-user)

        (defvar *my-search-engines*
          (list
           (make-instance 'search-engine
                          :name "Google"
                          :shortcut "goo"
                          #+nyxt-4 :control-url #+nyxt-3 :search-url
                          "https://duckduckgo.com/?q=~a")
           (make-instance 'search-engine
                          :name "MDN"
                          :shortcut "mdn"
                          #+nyxt-4 :control-url #+nyxt-3 :search-url
                          "https://developer.mozilla.org/en-US/search?q=~a")))

        (define-configuration browser
          ((restore-session-on-startup-p nil)
           (default-new-buffer-url (quri:uri "https://github.com/atlas-engineer/nyxt"))
           (external-editor-program (if (member :flatpak *features*)
                                        "flatpak-spawn --host emacsclient -r"
                                        "emacsclient -r"))
           #+nyxt-4
           (search-engine-suggestions-p nil)
           #+nyxt-4
           (search-engines (append %slot-default% *my-search-engines*))
           ;; Sets the font for the Nyxt UI (not for webpages).
           (theme (make-instance 'theme:theme
                                 :font-family "Iosevka"
                                 :monospace-font-family "Iosevka"))
           ;; Whether code sent to the socket gets executed.  You must understand the
           ;; risks before enabling this: a privileged user with access to your system
           ;; can then take control of the browser and execute arbitrary code under your
           ;; user profile.
           ;; (remote-execution-p t)
           ))
      '';
    };
    package = mkPackageOption pkgs "nyxt" { };
  };

  config = mkIf cfg.enable {
    yakumo.user.maid = {
      file = {
        # https://github.com/nix-community/home-manager/commit/2835e8ba0ad99ba86d4a5e497a962ec9fa35e48f
        xdg_config = mkIf (cfg.config != "") {
          # https://nyxt.atlas.engineer/documentation#configuration
          "nyxt/config.lisp".source = let
            inherit (builtins) isString;
            inherit (pkgs) writeText;
            nyxtConfig = if isString cfg.config then
              writeText "config.lisp" cfg.config
            else
              cfg.config;
          in nyxtConfig;
        };
      };
    };
  };
}
