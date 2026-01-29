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
  cfg = config.yakumo.desktop.terminal.wezterm;
  luaFormat = pkgs.formats.lua { };
  tomlFormat = pkgs.formats.toml { };
in
{
  options.yakumo.desktop.terminal.wezterm = {
    enable = mkEnableOption "wezterm";
    settings = mkOption {
      inherit (luaFormat) type;
      default = { };
      description = ''
        Wezterm configuration in Nix-representable Lua format.
        For more details, see: https://wezterm.org/config/files.html
      '';
    };
    # Wezterm CLI does not have an option for a color scheme file.
    # https://github.com/nix-community/home-manager/commit/44dcad5604785cc80c93bcb1b61140e3e10bf821
    # colorSchemes = mkOption {
    #   type = types.attrsOf (tomlFormat.type);
    #   default = { };
    # };
    package = mkPackageOption pkgs "wezterm" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Wezterm package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getName;
      inherit (pkgs) writeText;
      inherit (murakumo.wrappers) mkAppWrapper;

      weztermLua = luaFormat.generate "wezterm.lua" cfg.settings;
      weztermWrapped = mkAppWrapper {
        pkgs = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [
          "--config-file"
          weztermLua
        ];
      };
    in
    {
      yakumo.desktop.terminal.wezterm.packageWrapped = weztermWrapped;
      yakumo.user.packages = [ weztermWrapped ];
    }
  );
}
