{ self, lib, mkMurakumo, ... }:

let
  inherit (self) inputs;
  inherit (builtins)
    mapAttrs
    pathExists
    toString
    ;
  inherit (lib) getName mkDefault warn;

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
    { builder, baseModules }:
    name:
    {
      username,
      system,
      overlays ? defaultOverlays,
      extraModules ? [ ],
    }:
    let
      hostConfigPath = ../hosts/${name};
      userConfigPath = ../users/${username};
    in
    if !pathExists hostConfigPath then
      throwNotFoundErr {
        inherit name;
        target = "host";
        configPath = hostConfigPath;
      }
    else if !pathExists userConfigPath then
      throwNotFoundErr {
        name = username;
        target = "user";
        configPath = userConfigPath;
      }
    else
      builder {
        inherit system;
        modules = [
          baseModules
          hostConfigPath
          userConfigPath
          {
            # The name of this machine on the network.
            networking.hostName = mkDefault name;
            nixpkgs = {
              inherit overlays;
              config.allowUnfreePredicate = pkg: warn "Allowing unfree package: ${getName pkg}" true;
              hostPlatform = system;
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
    baseModules = self.nixosModules;
  });

  mkDarwinHosts = mapAttrs (mkHost {
    builder = inputs.darwin.lib.darwinSystem;
    baseModules = self.darwinModules;
  });
}
