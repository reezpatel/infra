# Display stack + storage arrays for divine: SDDM with Plasma as the default
# session (niri stays installed and selectable), mdadm RAID, NFS exports.
{ lib, ... }:
{
  # sddm comes from the kde module (wayland enabled there).
  # plasma6 and niri both set defaultSession at equal priority in nixpkgs -
  # plasma is the session this host boots into.
  services.displayManager.defaultSession = lib.mkForce "plasma";

  # Pin KWin (Plasma) to the RTX 3090 at PCI 0000:01:00.0; the RTX 5050
  # (0000:0e:00.0) stays display-free. All monitors must be plugged into the
  # 3090's outputs.
  #
  # KWIN_DRM_DEVICES is a colon-separated list, so the /dev/dri/by-path
  # symlink (which contains ':') cannot be used directly - the udev rule
  # creates a colon-free stable alias instead. ID_PATH is slot-dependent:
  # update it if the 3090 moves to another slot.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]", ENV{ID_PATH}=="pci-0000:01:00.0", SYMLINK+="dri/kwin-card"
  '';
  environment.sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/kwin-card";

  # Hardware notes:
  # - The 4K monitor needs HDMI 2.1 FRL for 4K@60 (its EDID caps TMDS at
  #   280MHz). FRL is cable-sensitive - use a certified Ultra High Speed
  #   HDMI cable; a marginal one causes intermittent black screens with
  #   "nvidia-modeset: WARNING: HDMI FRL link training failed" in dmesg.
  # - If KWin comes up blank after a GPU swap, clear its saved output state
  #   (rm -rf ~/.local/share/kscreen) from a TTY: a stale 4K@120 HDR profile
  #   once wedged the session when FRL failed to train on this GPU.

  # TODO: dynamic GPU handover to the Windows VM (win11.xml,
  # supplemental/gpu-handover.nix). The desktop now runs on the 3090
  # (0000:01:00.0/.1), so handing IT to the VM would kill the display
  # session - the display-free passthrough candidate is the 5050
  # (0000:0e:00.0/.1); update win11.xml addresses accordingly.

  systemd.services.fwupd-refresh.enable = lib.mkForce false;
  systemd.timers.fwupd-refresh.enable = lib.mkForce false;

  boot.kernelParams = [
    "usbcore.autosuspend=-1"
  ];

  # Assemble mdadm RAID arrays at boot
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  fileSystems."/mnt/ssd" = lib.mkForce {
    device = "/dev/md/raid1-ssd1";
    fsType = "xfs";
    options = [
      "noatime"
      "nofail"
    ];
  };

  services.nfs.server = {
    enable = true;
    # Pin the auxiliary RPC ports so they can be opened in the firewall
    # (nfs 2049 + rpcbind 111 + mountd/statd/lockd 20048).
    statdPort = 20048;
    lockdPort = 20049;
    mountdPort = 20050;
    exports = ''
      /mnt/ssd    192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      /mnt/nvme1  192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      111
      2049
      20048
      20049
      20050
    ];
    allowedUDPPorts = [
      111
      2049
      20048
      20049
      20050
    ];
  };

  # NFS server should wait for mounts
  systemd.services.nfs-server = {
    after = [
      "mnt-ssd.mount"
      "mnt-nvme1.mount"
    ];
    wants = [
      "mnt-ssd.mount"
      "mnt-nvme1.mount"
    ];
  };
}
