{
  lib,
  self,
  ...
}:
{
  flake.modules.nixos.rpi = { pkgs, ... }: {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;
    boot.loader.generic-extlinux-compatible.enable = true;

    boot.kernelPackages = pkgs.linuxPackages;
  };

  # SD-card booted fleet node (rpi2..rpi5). rpi1 moved to rpi-netboot.
  flake.modules.nixos.rpi-node = {
    imports = with self.modules.nixos; [
      base
      rpi
    ];
  };
}
