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
  cfg = config.yakumo.tools.ai.agents.gemini-cli;
  jsonFormat = pkgs.formats.json { };
in
{
  options.yakumo.tools.ai.agents.gemini-cli = {
    enable = mkEnableOption "Gemini CLI";
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Gemini CLI's settings.json in Nix-representable JSON format.";
    };
    package = mkPackageOption pkgs "gemini-cli" { };
    wrappedPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Gemini CLI package, including all configurations.
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
      settingsJson = jsonFormat.generate "settings.json" (cfg.settings // mcpServersAttr);
      geminiCliWrapped = mkWrapper {
        pkg = cfg.package;
        name = "${getName pkgs.gemini-cli}-${config.yakumo.user.name}";
        setEnv = {
          # https://geminicli.com/docs/cli/configuration/#settings-files
          GEMINI_CLI_SYSTEM_SETTINGS_PATH = settingsJson;
        };
      };
    in
    {
      yakumo.tools.ai.agents.gemini-cli.wrappedPackage = geminiCliWrapped;
      yakumo.user.packages = [ geminiCliWrapped ];
    }
  );
}
