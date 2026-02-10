{ inputs, config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.yakumo.ai.mcp.github;
in {
  options.yakumo.ai.mcp.github = {
    enable = mkEnableOption "GitHub MCP Server";
  };

  config = mkIf cfg.enable (let inherit (inputs) mcp-servers;
  in {
    yakumo.ai.mcp.servers = (mcp-servers.lib.evalModule pkgs {
      programs.github = {
        enable = true;
        envFile = config.sops.secrets.gh_token_for_mcp.path;
      };
    }).config.settings.servers;
  });
}
