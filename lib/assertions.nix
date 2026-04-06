{ lib }:

let
  inherit (lib) any concatMapStringsSep hasSuffix;
in
{
  # This doesn't technically assert whether the service is actually up, but simply checks
  # whether it's specified as any host's service in the project's metadata; therefore
  # the second param should always be the service list based on the metadata.
  # e.g., 'niwatazumi/tailscale'
  assertServiceUp = service: svcList: {
    assertion = any (hasSuffix service) svcList;
    message =
      let
        servicesStr = concatMapStringsSep "\n" (s: "- ${s}") svcList;
      in
      ''
        No hosts are running service '${service}'.
        The following services are currently up and running:
        ${servicesStr}
      '';
  };
}
