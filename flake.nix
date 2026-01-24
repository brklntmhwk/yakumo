{
  description = ''
    Yakumo is the sanctuary ー Rooted in the ancient song of building a dwelling
    for one's beloved, it stands as the home I weave from dotfiles, a shelter
    for my digital life.
  '';

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://brklntmhwk.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "brklntmhwk.cachix.org-1:mGWjznSV6FglvHR7/2sa4MrCtGHMLiAOc9Ru+tEkdyg="
    ];
  };

  inputs = {
    # Nixpkgs
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-25.05";
    nixpkgs-unstable.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";

    # Nix Darwin
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL integration
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home directory management
    nix-maid.url = "github:viperML/nix-maid";

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix utils
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop
    hyprland.url = "github:hyprwm/Hyprland";
    wezterm.url = "github:wezterm/wezterm?dir=nix";
    xremap.url = "github:xremap/nix-flake";
    zen-browser.url = "github:MarceColl/zen-browser-flake";

    # LLM Integration
    mcp-servers = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ametsuchi ── my ideal Emacs workstation
    ametsuchi = {
      url = "github:brklntmhwk/ametsuchi/dev";
      inputs.twist.follows = "twist";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    twist.url = "github:emacs-twist/twist.nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      treefmt-nix,
      ...
    }:
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
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
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

      nixosModules = import ./.;

      nixosConfigurations = lib'.mkNixOsHosts {
        tsutsuyami = {
          system = "x86_64-linux";
          username = "otogaki";
        };
      };

      # darwinModules = import ./.;

      # darwinConfigurations = lib'.mkDarwinHosts {
      #   momokagari = {
      #     system = "aarch64-darwin";
      #     username = "rkawata";
      #   };
      # };
    };
}
