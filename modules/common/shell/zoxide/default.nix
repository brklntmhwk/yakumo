{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.shell.zoxide;
  zshCfg = config.yakumo.shell.zsh;
in
{
  options.yakumo.shell.zoxide = {
    enable = mkEnableOption "zoxide";
    flags = mkOption {
      type = types.listOf types.str;
      # Replacing 'cd' with Zoxide is popular.
      default = [ "--cmd cd" ];
      example = [
        "--cmd cd"
        "--hook pwd"
      ];
      description = "Flags to pass to the 'zoxide init' command.";
    };
    package = mkPackageOption pkgs "zoxide" { };
  };

  config = mkIf cfg.enable {
    yakumo.user.packages = [ cfg.package ];

    yakumo.shell.zsh = mkIf zshCfg.enable (
      let
        inherit (builtins) concatStringsSep;
        inherit (lib) getExe;

        flagsStr = concatStringsSep " " cfg.flags;
      in
      {
        initExtra = ''
          # Initialize zoxide (generating the 'z' or 'cd' functions)
          eval "$(${getExe cfg.package} init zsh ${flagsStr})"
        '';
      }
    );

    # This writes the `eval "$(zoxide init bash)"` thingy to every shell's `interactiveShellInit` for you.
    # https://github.com/NixOS/nixpkgs/commit/825381d5ed73b78ce38cdd35474ef5ed3de1762f
    # programs.zoxide = {
    #   enable = true;
    #   enableZshIntegration = mkIf config.yakumo.shell.zsh.enable;
    #   package = cfg.package;
    # };
  };
}
