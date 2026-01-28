{
  self,
  lib,
  mkMurakumo,
  ...
}:

let
  inherit (self) inputs;
  inherit (builtins)
    mapAttrs
    pathExists
    toString
    ;
  inherit (lib)
    getName
    mkDefault
    optional
    warn
    ;

  defaultOverlays = [
    self.overlays.default
  ];

  throwNotFoundErr =
    {
      target,
      name,
      configPath,
    }:
    let
      configPathStr = toString configPath;
    in
    throw ''
      Error: The ${target} '${name}' not found.
      Expected configuration directory at: ${configPathStr}
      Ensure you have created `${configPathStr}/default.nix`.
    '';

  mkHost =
    { builder, platformType }:
    name:
    {
      username,
      system,
      overlays ? defaultOverlays,
      extraModules ? [ ],
    }:
    let
      hostConfigs = ../hosts/${name};
      userConfigs = ../users/${username};
    in
    if !pathExists hostConfigs then
      throwNotFoundErr {
        inherit name;
        target = "host";
        configPath = hostConfigs;
      }
    else if !pathExists userConfigs then
      throwNotFoundErr {
        name = username;
        target = "user";
        configPath = userConfigs;
      }
    else
      builder {
        inherit system;
        modules = [
          hostConfigs
          userConfigs
          {
            # The name of this machine on the network.
            networking.hostName = mkDefault name;
            nixpkgs = {
              inherit overlays;
              config.allowUnfreePredicate = pkg: warn "Allowing unfree package: ${getName pkg}" true;
              hostPlatformType = system;
            };
          }
          # Feed the current system's 'pkgs' into 'mkMurakumo' to build the Murakumo scope
          # for THIS specific architecture.
          (
            { pkgs, ... }:
            {
              _module.args.murakumo = mkMurakumo pkgs;
            }
          )
        ]
        ++ optional (platformType == "nixos") attrValues self.nixosModules
        ++ optional (platformType == "darwin") attrValues self.darwinModules
        ++ extraModules;

        # Put these into the modules' scope and make them accesible.
        specialArgs = {
          inherit
            inputs
            name
            username
            system
            ;
        };
      };
in
{
  mkNixOsHosts = mapAttrs (mkHost {
    builder = inputs.nixpkgs.lib.nixosSystem;
    platformType = "nixos";
  });

  mkDarwinHosts = mapAttrs (mkHost {
    builder = inputs.darwin.lib.darwinSystem;
    platformType = "darwin";
  });
}
