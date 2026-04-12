{lib, ...}: {
  moduleRegistry.nixos.rpi = {pkgs, ...}: {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.kernelPackages = pkgs.linuxPackages;
  };
}
