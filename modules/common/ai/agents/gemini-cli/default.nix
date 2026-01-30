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
  cfg = config.yakumo.ai.agents.gemini-cli;
  jsonFormat = pkgs.formats.json { };
in
{
  options.yakumo.ai.agents.gemini-cli = {
    enable = mkEnableOption "Gemini CLI";
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Gemini CLI's settings.json in Nix-representable JSON format.";
    };
    package = mkPackageOption pkgs "gemini-cli" { };
    packageWrapped = mkOption {
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
      inherit (murakumo.wrappers) mkAppWrapper;

      mcpCfg = config.yakumo.ai.mcp;
      mcpServersAttr = {
        mcpServers = mcpCfg.servers;
      };
      settingsJson = jsonFormat.generate "settings.json" (cfg.settings // mcpServersAttr);
      geminiCliWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName pkgs.gemini-cli}-${config.yakumo.user.name}";
        env = {
          # https://geminicli.com/docs/cli/configuration/#settings-files
          GEMINI_CLI_SYSTEM_SETTINGS_PATH = settingsJson;
        };
      };
    in
    {
      yakumo.ai.agents.gemini-cli.packageWrapped = geminiCliWrapped;
      yakumo.user.packages = [ geminiCliWrapped ];
    }
  );
}
