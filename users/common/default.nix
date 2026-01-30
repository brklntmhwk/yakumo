{ pkgs, ... }:

{
  time.timeZone = "Asia/Tokyo";

  environment.systemPackages = (
    let
      inherit (pkgs) hunspellDicts;
    in
    builtins.attrValues {
      # Dictionaries for multiple languages
      inherit (hunspellDicts)
        en-us
        en-gb-ise
        es-any
        ;
    }
  );
}
