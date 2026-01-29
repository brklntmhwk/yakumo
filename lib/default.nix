{ self, lib }:

let
  inherit (lib) makeScope;

  # Murakumo is a collection of library functions whose scope encapsulates
  # themselves and allows for referring to each other.
  # This will later be available inside the NixOS and Darwin module systems.
  mkMurakumo =
    pkgs:
    makeScope pkgs.newScope (final: {
      # Inject 'self' into this scope so the lib modules below can refer to it.
      inherit self;

      # Don't include 'hosts' here. Treat it specially.
      assertions = final.callPackage ./assertions.nix { };
      configs = final.callPackage ./configs.nix { };
      generators = final.callPackage ./generators.nix { };
      modules = final.callPackage ./modules.nix { };
      utils = final.callPackage ./utils.nix { };
      wrappers = final.callPackage ./wrappers.nix { };
    });

  hosts = import ./hosts.nix {
    inherit self lib mkMurakumo;
  };
  modules = import ./modules.nix {
    inherit lib;
  };
in
{
  inherit mkMurakumo;
  inherit (hosts) mkNixOsHosts mkDarwinHosts;
  inherit (modules) mapFilterModules;
}
