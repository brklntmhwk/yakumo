{
  self,
  lib,
  mkMurakumo,
  ...
}:

let
  inherit (self) inputs;
  inherit (builtins) mapAttrs pathExists toString;
  inherit (lib)
    genAttrs
    getName
    mkDefault
    optionals
    warn
    ;

  defaultOverlays = [ self.overlays.default ];

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

  mkSystem =
    {
      builder,
      platformType,
      isGuest ? false,
    }:
    name:
    {
      username,
      system,
      overlays ? defaultOverlays,
      extraModules ? [ ],
      hostName ? name,
      hostConfigPath ? ../hosts/${name},
      # Guests are typically headless server nodes, so we default to skipping the user profile.
      userConfigPath ? if isGuest then null else ../users/${username}/hosts/${name},
    }:
    if hostConfigPath != null && !pathExists hostConfigPath then
      throwNotFoundErr {
        inherit name;
        target = "host";
        configPath = hostConfigPath;
      }
    else if userConfigPath != null && !pathExists userConfigPath then
      throwNotFoundErr {
        name = username;
        target = "user";
        configPath = userConfigPath;
      }
    else
      builder {
        modules = [
          hostConfigPath
          {
            # The name of this machine on the network.
            networking.hostName = mkDefault hostName;
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
        # Use `lib.optionals` instead of `lib.optional` here;
        # the former returns the given list as is if the condition is true.
        ++ optionals (userConfigPath != null) [ userConfigPath ]
        ++ optionals (platformType == "nixos") [ self.nixosModules.default ]
        ++ optionals (platformType == "darwin") [ self.darwinModules.default ]
        ++ optionals isGuest [ inputs.microvm.nixosModules.microvm ]
        ++ extraModules;

        # Put these into the modules' scope and make them accesible.
        specialArgs = {
          inherit
            inputs
            name
            username
            system
            ;
          flakeRoot = self;
        };
      };
in
{
  forAllSystems = genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  mkNixOsHosts = mapAttrs (mkSystem {
    builder = inputs.nixpkgs.lib.nixosSystem;
    platformType = "nixos";
  });

  mkNixOsGuests = mapAttrs (mkSystem {
    builder = inputs.nixpkgs.lib.nixosSystem;
    platformType = "nixos";
    isGuest = true;
  });

  mkDarwinHosts = mapAttrs (mkSystem {
    builder = inputs.darwin.lib.darwinSystem;
    platformType = "darwin";
  });
}
