{
  self,
  lib,
  mkMurakumo,
  ...
}:

let
  inherit (self) inputs;
  inherit (builtins)
    filter
    fromTOML
    listToAttrs
    pathExists
    readFile
    toString
    ;
  inherit (lib)
    concatMap
    findFirst
    genAttrs
    getName
    hasPrefix
    hasSuffix
    mkDefault
    nameValuePair
    optionals
    unique
    warn
    ;

  defaultOverlays = [ self.overlays.default ];
  rootMeta =
    let
      m = fromTOML (readFile ../metadata.toml);
    in
    m
    // {
      allServices = unique (concatMap (x: x.services or [ ]) ((m.hosts or [ ]) ++ (m.guests or [ ])));
    };
  # Fill the guest entries with some of their host's properties (e.g., `platform`).
  enrichedGuests = map (
    guest:
    let
      parentHost = findFirst (
        h: h.name == guest.hostname
      ) (throw "Parent host ${guest.hostname} not found for guest ${guest.name}") (rootMeta.hosts or [ ]);
    in
    guest
    // {
      inherit (parentHost) username platform variant;
    }
  ) (rootMeta.guests or [ ]);

  # These may come across as weird logic, but are fine; the root metadata, that they'll
  # refer to, are the Single Source of Truth for global constants.
  isNixOsSystem = s: hasSuffix "linux" (s.platform or "") && hasPrefix "nixos" (s.variant or "");
  isDarwinSystem = s: hasSuffix "darwin" (s.platform or "") && (s.variant or "") == "nix-darwin";

  nixosHostMeta = filter isNixOsSystem (rootMeta.hosts or [ ]);
  nixosGuestMeta = filter isNixOsSystem enrichedGuests;
  darwinHostMeta = filter isDarwinSystem (rootMeta.hosts or [ ]);

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
      metadata,
      builder,
      overlays ? defaultOverlays,
      isGuest ? false,
    }:
    let
      inherit (metadata)
        name
        username
        platform
        variant
        ;
      parentHostName = metadata.hostname or null;
      hostConfigPath =
        if isGuest && parentHostName != null then
          ../hosts/${parentHostName}/guests/${name}
        else
          ../hosts/${name};
      # Guests are typically headless server nodes, so we default to skipping the user profile.
      userConfigPath = if isGuest then null else ../users/${username}/hosts/${name};
    in
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
            networking.hostName = mkDefault name;
            nixpkgs = {
              inherit overlays;
              config.allowUnfreePredicate = pkg: warn "Allowing unfree package: ${getName pkg}" true;
              hostPlatform = platform;
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
        # the former returns the given list as is if the condition is met.
        ++ optionals (userConfigPath != null) [ userConfigPath ]
        ++ optionals (isNixOsSystem metadata) [ self.nixosModules.default ]
        ++ optionals (isDarwinSystem metadata) [ self.darwinModules.default ]
        ++ optionals isGuest [ inputs.microvm.nixosModules.microvm ]
        ++ optionals (variant == "nixos-apple-silicon") [
          inputs.nixos-apple-silicon.nixosModules.default
        ]
        ++ optionals (variant == "nixos-wsl") [ inputs.nixos-wsl.nixosModules.default ];

        # Put these into the modules' scope and make them accesible.
        specialArgs = {
          inherit
            inputs
            name
            username
            rootMeta
            ;
          rootPath = self;
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

  mkNixOsHosts = listToAttrs (
    map (
      host:
      nameValuePair host.name (mkSystem {
        metadata = host;
        builder = inputs.nixpkgs.lib.nixosSystem;
      })
    ) nixosHostMeta
  );

  mkNixOsGuests = listToAttrs (
    map (
      guest:
      nameValuePair guest.name (mkSystem {
        metadata = guest;
        builder = inputs.nixpkgs.lib.nixosSystem;
        isGuest = true;
      })
    ) nixosGuestMeta
  );

  mkDarwinHosts = listToAttrs (
    map (
      host:
      nameValuePair host.name (mkSystem {
        metadata = host;
        builder = inputs.darwin.lib.darwinSystem;
      })
    ) darwinHostMeta
  );
}
