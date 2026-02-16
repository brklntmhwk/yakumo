{ pkgs }:

let
  inherit (builtins) readDir;
  inherit (pkgs) callPackage lib;
  inherit (lib) filterAttrs mapAttrs;

  packageDirs = filterAttrs (name: type: type == "directory") (readDir ./.);
  mkPackage = name: _: callPackage (./. + "/${name}") { };
in
mapAttrs mkPackage packageDirs
