{ pkgs, lib, self, ... }:

let
  inherit (lib) mkForce;
in
pkgs.testers.runNixOSTest {
  name = "yosuga-test";
  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../../modules/nixos/system/persistence/yosuga ];

    # VM Storage Layout (Tmpfs as root).
    virtualisation.fileSystems = {
      "/" = {
        device = mkForce "none";
        fsType = mkForce "tmpfs";
        options = [ "defaults" "size=50%" "mode=755" ];
      };
      "/yosuga" = {
        device = "/dev/vdb"; # The test runner attaches a 2nd disk here.
        fsType = "ext4";
        # Ensure the physical disk is ready before Yosuga tries to bind from it.
        neededForBoot = true;
      };
    };

    yakumo.system.persistence.yosuga = {
      enable = true;
      persistentStoragePath = "/yosuga";
      directories = [{
        name = "/var/lib/precious_data";
        mode = "0700";
      }];
      files = [{ name = "/etc/precious_file"; }];
    };

    # Disable stuff that slows down tests.
    documentation.enable = false;
    networking.useDHCP = false;
  };

  testScript = ''
    # --- PHASE 1: FIRST BOOT ---
    machine.wait_for_unit("default.target")

    # 1. Create data that SHOULD persist
    machine.succeed("mkdir -p /var/lib/precious_data")
    machine.succeed("echo 'I am eternal' > /var/lib/precious_data/state.txt")
    machine.succeed("echo 'I am a file' > /etc/precious_file")

    # 2. Create data that SHOULD be erased (The "Control" group)
    machine.succeed("touch /var/lib/garbage.txt")

    # 3. Verify Bind Mounts are active
    # The real storage (/yosuga) should now contain the data we wrote to the bind mount
    machine.succeed("grep 'I am eternal' /yosuga/var/lib/precious_data/state.txt")

    # --- PHASE 2: REBOOT ---
    # This simulates a power cycle. The 'tmpfs' root is lost from RAM.
    machine.crash()
    machine.start()
    machine.wait_for_unit("default.target")

    # --- PHASE 3: VERIFICATION ---

    # 1. Check Persistence (Success Case)
    print("Checking persistent directory...")
    machine.succeed("grep 'I am eternal' /var/lib/precious_data/state.txt")

    print("Checking persistent file...")
    machine.succeed("grep 'I am a file' /etc/precious_file")

    # 2. Check Erasure (Success Case)
    print("Checking ephemeral erasure...")
    machine.fail("ls /var/lib/garbage.txt") # This command MUST fail for the test to pass

    # 3. Check Permissions (Granularity Case)
    # We set mode="0700" in the config; verify it was applied
    status = machine.succeed("stat -c '%a' /var/lib/precious_data").strip()
    if status != "700":
        raise Exception(f"Wrong permissions on persisted dir: expected 700, got {status}")
  '';
}
