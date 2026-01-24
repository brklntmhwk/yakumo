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
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.programs.git;
in
{
  options.yakumo.programs.git = {
    enable = mkEnableOption "git";
    # https://github.com/NixOS/nixpkgs/commit/49f6869f71fb2724674ccc18670bbde70843d43f
    config = mkOption {
      type =
        let
          gitini = types.attrsOf (types.attrsOf types.anything);
        in
        types.either gitini (types.listOf gitini)
        // {
          merge =
            loc: defs:
            let
              config =
                builtins.foldl'
                  (
                    acc:
                    { value, ... }@x:
                    acc
                    // (
                      if builtins.isList value then
                        {
                          ordered = acc.ordered ++ value;
                        }
                      else
                        {
                          unordered = acc.unordered ++ [ x ];
                        }
                    )
                  )
                  {
                    ordered = [ ];
                    unordered = [ ];
                  }
                  defs;
            in
            [ (gitini.merge loc config.unordered) ] ++ config.ordered;
        };
      default = [ ];
      description = ''
        Git configuration in Nix-representable format.
        For the valid setting options, see: https://www.mankier.com/1/git-config
      '';
      example = {
        init.defaultBranch = "main";
        url."https://github.com/".insteadOf = [
          "gh:"
          "github:"
        ];
      };
    };
    lfs = {
      enable = lib.mkEnableOption "git-lfs (Large File Storage)";
      package = lib.mkPackageOption pkgs "git-lfs" { };
      enablePureSSHTransfer = lib.mkEnableOption "Enable pure SSH transfer in server side by adding git-lfs-transfer to environment.systemPackages";
    };
    package = mkPackageOption pkgs "git" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Git package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (
      let
        inherit (murakumo.wrappers) mkAppWrapper;
        inherit (lib)
          concatMapStringsSep
          generators
          getName
          optional
          ;
        inherit (pkgs) writeText;

        gitConfig = writeText "config" (concatMapStringsSep "\n" generators.toGitINI cfg.config);
        gitWrapped = mkAppWrapper {
          pkgs = cfg.package;
          name = "${getName cfg.package}-${config.yakumo.user.name}";
          env = {
            GIT_CONFIG_GLOBAL = gitConfig;
          };
          # This takes precedence over any other configurations, which is undesirable.
          # flags = [
          #   "-c"
          #   "include.path=${gitConfig}"
          # ];
        };
      in
      {
        yakumo.programs.git.packageWrapped = gitWrapped;
        yakumo.user.packages = [
          gitWrapped
        ]
        ++ optional cfg.lfs.enable cfg.lfs.package
        ++ optional cfg.lfs.enablePureSSHTransfer [ pkgs.git-lfs-transfer ];
      }
    )
    (mkIf cfg.lfs.enable {
      yakumo.programs.git.config = {
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
    })
  ]);
}
