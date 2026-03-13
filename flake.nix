{
  description = ''
    Yakumo is the sanctuaryーRooted in the ancient song of building a dwelling
    for one's beloved, it stands as the home I weave from dotfiles, a shelter
    for my digital life.
  '';

  nixConfig = {
    extra-substituters = [
      # "https://hyprland.cachix.org"
      "https://brklntmhwk.cachix.org"
    ];
    extra-trusted-public-keys = [
      # "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "brklntmhwk.cachix.org-1:mGWjznSV6FglvHR7/2sa4MrCtGHMLiAOc9Ru+tEkdyg="
    ];
  };

  inputs = {
    # --- Nixpkgs ---
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-25.11";
    nixpkgs-unstable.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";

    # --- Apple Silicon support for NixOS ---
    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";

    # --- Nix Darwin ---
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- WSL integration ---
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Home directory management (Limited to NixOS) ---
    nix-maid.url = "github:viperML/nix-maid";

    # --- Secrets ---
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- VMs ---
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- LLM Integration ---
    mcp-servers = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Ametsuchi ── my ideal Emacs workstation ---
    ametsuchi = {
      url = "github:brklntmhwk/ametsuchi/dev";
      inputs.twist.follows = "twist";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    twist.url = "github:emacs-twist/twist.nix";

    # --- Desktop ---
    # hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      lib' = import ./lib {
        inherit self;
        inherit (nixpkgs) lib;
      };
    in
    {
      overlays.default = lib'.mkOverlays {
        packagesDir = ./pkgs;
        extraOverlays = [
          # Add manual overrides and external overlays here.
        ];
      };

      packages = lib'.forAllSystems (system: lib'.mkPackages ./pkgs nixpkgs.legacyPackages.${system} { });

      checks = lib'.forAllSystems (
        system:
        lib'.mkPackages ./tests nixpkgs.legacyPackages.${system} {
          inherit self;
        }
      );

      devShells = lib'.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = import ./shell.nix { inherit pkgs; };
        }
      );

      formatter = lib'.forAllSystems (
        system:
        let
          inherit (pkgs) callPackage;
          pkgs = nixpkgs.legacyPackages.${system};
        in
        callPackage ./formatter.nix { }
      );

      # These are not for external use.
      nixosModules.default = {
        imports = lib'.mapFilterModulesRecursively ./modules import [ "darwin" ];
      };

      nixosConfigurations =
        lib'.mkNixOsHosts {
          tsutsuyami = {
            system = "x86_64-linux";
            username = "otogaki";
          };
          utsusemi = {
            system = "x86_64-linux";
            username = "otogaki";
            extraModules = [ inputs.nixos-wsl.nixosModules.default ];
          };
          shinonome = {
            system = "aarch64-linux";
            username = "otogaki";
            extraModules = [
              inputs.nixos-apple-silicon.nixosModules.default
            ];
          };
          # niwatazumi = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # sazanami = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # tamazusa = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
        }
        // lib'.mkNixOsGuests {
          # hayase = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # minamo = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # minamoto = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # wadatsumi = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # migiwa = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # mizukagami = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # shibuki = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # fumi = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # hibiki = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
          # musubi = {
          #   system = "x86_64-linux";
          #   username = "otogaki";
          # };
        };

      # These are not for external use.
      # darwinModules.default = {
      #   imports = lib'.mapFilterModulesRecursively ./modules import [ "nixos" ];
      # };

      # darwinConfigurations = lib'.mkDarwinHosts {
      #   momokagari = {
      #     system = "aarch64-darwin";
      #     username = "rkawata";
      #   };
      # };
    };
}
