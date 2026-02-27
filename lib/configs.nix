{ lib, runCommand }:
let
  inherit (builtins)
    attrNames
    concatStringsSep
    elem
    foldl'
    isAttrs
    isPath
    substring
    toString
    ;
  inherit (lib)
    filterAttrs
    functionArgs
    hasPrefix
    intersectLists
    isDerivation
    isOption
    mkAliasDefinitions
    mapAttrs
    mapAttrsToList
    mkOption
    naturalSort
    removePrefix
    stringToCharacters
    ;
in
rec {
  # https://github.com/NixOS/nixpkgs/commit/95674de399b4c880f16059f8e2ce84e7388842d8
  genFinalPackage =
    pkg: args:
    let
      expectedArgs = naturalSort (attrNames args);
      existingArgs = naturalSort (intersectLists expectedArgs (attrNames (functionArgs pkg.override)));
    in
    if existingArgs != expectedArgs then pkg else pkg.override args;

  hexToRgba =
    hex: alpha:
    let
      # Strip the leading '#' if it exists.
      cleanHex = if hasPrefix "#" hex then removePrefix "#" hex else hex;

      # Extract RR, GG, BB pairs using substring (offset, length, string).
      rHex = substring 0 2 cleanHex;
      gHex = substring 2 2 cleanHex;
      bHex = substring 4 2 cleanHex;

      # Map hex characters to integer values.
      hexToInt =
        hexStr:
        let
          hexMap = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "A" = 10;
            "B" = 11;
            "C" = 12;
            "D" = 13;
            "E" = 14;
            "F" = 15;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
          };
          chars = stringToCharacters hexStr;
        in
        foldl' (acc: c: acc * 16 + hexMap.${c}) 0 chars;

      # Convert each pair to a decimal integer
      r = hexToInt rHex;
      g = hexToInt gHex;
      b = hexToInt bHex;
    in
    "rgba(${toString r}, ${toString g}, ${toString b}, ${toString alpha})";
}
