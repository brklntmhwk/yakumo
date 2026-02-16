{
  description = ''
    Yakumo is the sanctuary ー Rooted in the ancient song of building a dwelling
    for one's beloved, it stands as the home I weave from dotfiles, a shelter
    for my digital life.
  '';

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://brklntmhwk.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
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

    # --- Declarative disk partitioning ---
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Nix utils ---
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # --- Desktop ---
    hyprland.url = "github:hyprwm/Hyprland";
    xremap.url = "github:xremap/nix-flake";

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
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      lib' = import ./lib {
        inherit self;
        inherit (nixpkgs) lib;
      };
    in
    {
      overlays.default = import ./overlays { inherit (nixpkgs) lib; };

      packages = forAllSystems (system: import ./pkgs { pkgs = nixpkgs.legacyPackages.${system}; });

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./tests { inherit pkgs self; }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              stylua.enable = true;
              taplo.enable = true;
              yamlfmt.enable = true;
            };
          };
        in
        treefmtEval.config.build.wrapper
      );

      # These are not for external use.
      nixosModules.default = {
        imports = lib'.mapFilterModulesRecursively ./modules import [ "darwin" ];
      };

      nixosConfigurations = lib'.mkNixOsHosts {
        tsutsuyami = {
          system = "x86_64-linux";
          username = "otogaki";
        };
        utsusemi = {
          system = "x86_64-linux";
          username = "otogaki";
          extraModules = [ inputs.nixos-wsl.nixosModules.default ];
        };
        # shinonome = {
        #   system = "aarch64-linux";
        #   username = "otogaki";
        #   extraModules = [
        #     inputs.nixos-apple-silicon.nixosModules.default
        #   ];
        # };
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
