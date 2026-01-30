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
  cfg = config.yakumo.ai.agents.claude-code;
  jsonFormat = pkgs.formats.json { };
in
{
  options.yakumo.ai.agents.claude-code = {
    enable = mkEnableOption "Claude Code";
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Claude Code's settings.json in Nix-representable JSON format.";
    };
    package = mkPackageOption pkgs "claude-code" { };
    packageWrapped = mkOption {
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
      inherit (murakumo.wrappers) mkAppWrapper;

      mcpCfg = config.yakumo.ai.mcp;
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
      claudeCodeWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName pkgs.claude-code}-${config.yakumo.user.name}";
        flags = [
          "--settings"
          settingsJson
        ];
      };
    in
    {
      yakumo.ai.agents.claude-code.packageWrapped = claudeCodeWrapped;
      yakumo.user.packages = [ claudeCodeWrapped ];
    }
  );
}
