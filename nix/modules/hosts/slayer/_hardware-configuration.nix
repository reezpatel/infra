{
  modulesPath,
  lib,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.useDHCP = false;
  networking.networkmanager.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  services.dbus.implementation = "broker";
}
