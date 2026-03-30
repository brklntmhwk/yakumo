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
  cfg = config.yakumo.tools.ai.agents.claude-code;
  jsonFormat = pkgs.formats.json { };
in
{
  options.yakumo.tools.ai.agents.claude-code = {
    enable = mkEnableOption "Claude Code";
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Claude Code's settings.json in Nix-representable JSON format.";
    };
    package = mkPackageOption pkgs "claude-code" { };
    wrappedPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Claude Code package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getName;
      inherit (murakumo.wrappers) mkWrapper;

      mcpCfg = config.yakumo.tools.ai.mcp;
      mcpServersAttr = {
        mcpServers = mcpCfg.servers;
      };
      settingsJson = jsonFormat.generate "settings.json" (
        cfg.settings
        // mcpServersAttr
        // {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        }
      );
      claudeCodeWrapped = mkWrapper {
        pkg = cfg.package;
        name = "${getName pkgs.claude-code}-${config.yakumo.user.name}";
        prependFlags = [
          "--settings"
          settingsJson
        ];
      };
    in
    {
      yakumo.tools.ai.agents.claude-code.wrappedPackage = claudeCodeWrapped;
      yakumo.user.packages = [ claudeCodeWrapped ];
    }
  );
}
