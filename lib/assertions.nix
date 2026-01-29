{ lib }:

let
  inherit (builtins) map;
  inherit (lib)
    concatStringsSep
    elem
    sort
    ;
in
{
  # https://github.com/nix-community/home-manager/commit/5f433eb164832fc507c3e1ba2a798f8c00578316
  # NOTE: Deprecated in favor of a directory-based platform modularization.
  assertPlatform = module: pkgs: platforms: {
    assertion = elem pkgs.stdenv.hostPlatform.system platforms;
    message =
      let
        platformsStr = concatStringsSep "\n" (map (p: "  - ${p}") (sort (a: b: a < b) platforms));
      in
      ''
        The module ${module} does not support your platform. It only supports:
        ${platformsStr}
      '';
  };
}
