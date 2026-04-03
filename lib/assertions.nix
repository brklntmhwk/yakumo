{ lib }:

let
  inherit (lib) concatMapStringsSep elem;
in
{
  # This doesn't technically assert whether the service is up, but simply checks
  # whether it's specified as any host's service in the project's metadata; therefore
  # the second param should always be the service list based on the metadata.
  assertServiceUp = service: allServices: {
    assertion = elem service allServices;
    message =
      let
        servicesStr = concatMapStringsSep "\n" (s: "- ${s}") allServices;
      in
      ''
        No hosts run service '${service}'.
        The following services should be currently up and running:
        ${servicesStr}
      '';
  };
}
