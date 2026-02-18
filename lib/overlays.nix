# Based on:
# https://github.com/viperML/dotfiles/commit/62a757938bee8a0c44f5a7c0c5c2fef24e345c63
{ lib }:

let
  inherit (builtins) mapAttrs readDir;
  inherit (lib) composeManyExtensions filterAttrs optional;
in
{
  mkOverlays =
    {
      packagesDir ? null,
      extraOverlays ? [ ],
    }:
    let
      overlayAuto =
        if packagesDir == null then
          null
        else
          final: prev:
          let
            isDirectory = name: type: type == "directory";
            dirs = filterAttrs isDirectory (readDir packagesDir);
            callPackageByName = name: _: final.callPackage (packagesDir + "/${name}") { };
          in
          # Map over the directories to create the package set.
          mapAttrs callPackageByName dirs;

      allOverlays = (optional (overlayAuto != null) overlayAuto) ++ extraOverlays;
    in
    composeManyExtensions allOverlays;
}
