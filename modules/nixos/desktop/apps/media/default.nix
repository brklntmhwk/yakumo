{
  config,
  murakumo,
  ...
}:

let
  inherit (murakumo.utils) getDirNamesRecursive;
  nixosMedia = getDirNamesRecursive ./.;
in
{
  # Append NixOS-specific modules to the global registry.
  config.yakumo.desktop.apps.media.availableModules = nixosMedia;
}
