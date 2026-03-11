{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (inputs.microvm.lib) hypervisors;
  cfg = config.yakumo.system.virt.microvm.guest;
in
{
  imports = [
    inputs.microvm.nixosModules.microvm
  ];

  options.yakumo.system.virt.microvm.guest = {
    enable = mkEnableOption "MicroVM guest infrastructure";
    macAddress = mkOption {
      type = types.str;
      example = "02:00:00:00:00:01";
      description = "The MAC address for the VM's network interface.";
    };
    tapInterface = mkOption {
      type = types.str;
      default = "tap-${config.networking.hostName}";
      description = "The name of the virtual tap interface created on the host.";
    };
    hostDataDir = mkOption {
      type = types.str;
      default = "/mnt/data/vms/${config.networking.hostName}";
      description = "The base path on the bare-metal host where this VM's state is stored.";
    };
    hypervisor = mkOption {
      type = types.enum hypervisors;
      default = "qemu";
      description = ''
        Hypervisor for the VM.
        Choose one of: ${concatStringsSep ", " hypervisors}
      '';
    };
    memorySize = mkOption {
      type = types.int;
      default = 1024;
      description = "RAM allocated to the MicroVM in Megabytes.";
    };
    vcpu = mkOption {
      type = types.int;
      default = 2;
      description = "Number of virtual CPU cores allocated to the MicroVM.";
    };
  };

  config = mkIf cfg.enable {
    microvm = {
      inherit (cfg)
        hypervisor # Default: 'qemu'
        vcpu # Default: 1
        ;
      mem = cfg.memorySize; # Default: 512
      # The network connection to the host.
      interfaces = [
        {
          type = "tap"; # Options: 'user', 'macvtap', 'bridge'
          id = cfg.tapInterface;
          mac = cfg.macAddress;
        }
      ];
      shares = [
        {
          proto = "virtiofs"; # Default: '9p' (Options: 'virtiofs')
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/store";
        }
      ];
      # Path to the writable /nix/store overlay.
      # This allows you to build Nix derivations inside the VM.
      writableStoreOverlay = "/nix/.rw-store"; # Default: null
    };
  };
}
