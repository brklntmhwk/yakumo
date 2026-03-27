{
  config,
  lib,
}:

let
  inherit (builtins) foldl' isString;
  inherit (lib) recursiveUpdate;
  cfg = config.yakumo.tools.misc.git;

  configList = if isList cfg.config then cfg.config else [ cfg.config ];
  flatGitConfig = foldl' recursiveUpdate { } configList;
  gitEmail = flatGitConfig.user.email or null;
  gitSigningKey = flatGitConfig.user.signingkey or null;
in
{
  email = gitEmail;
  key = gitSigningKey;
  hasValidSigningSetup =
    isString gitEmail && gitEmail != "" && isString gitSigningKey && gitSigningKey != "";
}
