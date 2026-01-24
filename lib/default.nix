{ self, lib }:

let
  # Murakumo is a collection of library functions whose scope encapsulates
  # themselves and allows for referring to each other.
  # This will later be available inside the NixOS and Darwin module systems.
  mkMurakumo =
    pkgs:
    lib.makeScope pkgs.newScope (final: {
      # Inject 'self' into this scope so the lib modules below can refer to it.
      inherit self;

      # Don't include 'hosts' here. Treat it specially.
      assertions = final.callPackage ./assertions.nix { };
      configs = final.callPackage ./configs.nix { };
      generators = final.callPackage ./generators.nix { };
      utils = final.callPackage ./utils.nix { };
      wrappers = final.callPackage ./wrappers.nix { };
    });

  hosts = import ./hosts.nix {
    inherit self lib mkMurakumo;
  };
in
{
  inherit mkMurakumo;
  inherit (hosts) mkNixOsHosts mkDarwinHosts;
}
