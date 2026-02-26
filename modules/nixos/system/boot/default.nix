{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    mkDefault
    mkForce
    mkIf
    mkMerge
    ;
  inherit (murakumo.platforms) isx86_64 isAarch64;
  systemRole = config.yakumo.system.role;
  isWsl = (config ? wsl) && config.wsl.enable;
  isAsahi = isAarch64 && (config ? hardware.asahi);
in
{
  config = mkMerge [
    {
      boot = {
        kernelPackages = mkDefault pkgs.linuxPackages; # Stable default.
        # Kernel modules to be loaded in the second stage of the boot process.
        kernelModules = [
          "tcp_bbr" # TCP Bottleneck Bandwidth and Round-Trip
        ];
        kernel.sysctl = {
          # 'tcp_bbr' requires this.
          # Improve throughput and latency on WAN links.
          "net.ipv4.tcp_congestion_control" = "bbr";
        };
        loader = mkIf (!isWsl) {
          efi.canTouchEfiVariables = mkDefault true;
          systemd-boot = {
            enable = mkDefault true;
            # Maximum number of latest generations in the boot menu.
            configurationLimit = mkDefault 10;
            # Add Memtest86+ (Memory testing tool) to the boot menu.
            memtest86.enable = mkIf isx86_64 (mkDefault true);
          };
          timeout = mkDefault 3;
        };
        # initrd.systemd.enable = true;
      };
    }
    (mkIf isAsahi {
      boot.loader.efi.canTouchEfiVariables = mkForce false;
    })
    (mkIf (systemRole == "workstation") {
      boot = {
        # We don't play games on our workstations, so Xanmod is not our option.
        kernelPackages = mkIf isx86_64 pkgs.linuxKernel.packages.linux_zen;
        kernelModules = [ ];
        kernel = { };
        # Kernel Modules needed to mount the root file system.
        # In most cases, these are automatically configured in
        # 'hardware-configuration.nix' already.
        initrd.availableKernelModules = [
          "xhci_pci" # USB 3.x
          "ahci" # SATA
          "usbhid" # USB Human Interface Devices
          "usb_storage" # USB Storage Devices
          "sd_mod" # SCSI/SATA disks
        ];
      };
    })
    (mkIf (systemRole == "server") {
      boot = {
        kernelPackages = mkIf isx86_64 pkgs.linuxKernel.packages.linux_6_12_hardened;
      };
    })
  ];
}
