{ pkgs, lib, ... }:

let
  inherit (builtins) attrValues;
  inherit (lib) elem mkEnableOption mkIf mkMerge mkOption types;
  supportedProtocols = [
    "fido-u2f" # FIDO-U2F
    "piv" # Peasonal Identity Verification
  ];
in {
  options.yakumo.system.security.yubikey = {
    enable = mkEnableOption "Yubikey integrations";
    protocols = mkOption {
      type = types.listOf (types.enum supportedProtocols);
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.udev.packages =
        attrValues { inherit (pkgs) yubikey-personalization; };
      environment.systemPackages = attrValues {
        inherit (pkgs)
          yubikey-manager # The modern CLI tool (ykman)
          yubikey-personalization # The legacy tools
          yubikey-touch-detector # Lets you know when Yubikey's waiting for skinship.
        ;
      };
    }
    (mkIf (pkgs.stdenv.isLinux && (elem "piv" cfg.protocols)) {
      # Enable PCSC-Lite daemon for accessing smart cards.
      services.pcscd.enable = true;
    })
    (mkIf (pkgs.stdenv.isLinux && (elem "fido-u2f" cfg.protocols)) {
      # https://nixos.wiki/wiki/Yubikey
      security.pam.services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
    })
  ]);
}
