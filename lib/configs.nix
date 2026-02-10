{ lib, runCommand }:
let
  inherit (builtins) attrNames concatStringsSep elem isAttrs isPath toString;
  inherit (lib)
    filterAttrs functionArgs intersectLists isDerivation isOption
    mkAliasDefinitions mapAttrs mapAttrsToList mkOption naturalSort;
in rec {
  mkConfig = { name, src, replacements ? { }, }:
    let
      toStr = v: if isDerivation v || isPath v then "${v}" else toString v;
      replaceFlags =
        mapAttrsToList (k: v: "--replace '${k}' '${toStr v}'") replacements;
      cmd = concatStringsSep " " replaceFlags;
    in runCommand name { inherit src; } ''
      substitute "$src" "$out" ${cmd}
    '';

  # https://github.com/NixOS/nixpkgs/commit/95674de399b4c880f16059f8e2ce84e7388842d8
  genFinalPackage = pkg: args:
    let
      expectedArgs = naturalSort (attrNames args);
      existingArgs = naturalSort
        (intersectLists expectedArgs (attrNames (functionArgs pkg.override)));
    in if existingArgs != expectedArgs then pkg else pkg.override args;

  mkInherit = opt: mkOption (filterAttrs (k: _: elem k [ ]) opt);

  mkRecursiveAlias = optsFrom: structure:
    mapAttrs (n: v:
      if isOption v then
        mkAliasDefinitions optsFrom.${n}
      else if isAttrs v then
        mkRecursiveAlias optsFrom.${n} v
      else
        { }) structure;
}
