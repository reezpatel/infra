# Display stack + storage arrays for divine: SDDM with Plasma as the default
# session (niri stays installed and selectable), mdadm RAID, NFS exports.
{ lib, ... }:
{
  # sddm comes from the kde module (wayland enabled there).
  # plasma6 and niri both set defaultSession at equal priority in nixpkgs -
  # plasma is the session this host boots into.
  services.displayManager.defaultSession = lib.mkForce "plasma";

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
