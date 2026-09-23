{...}: {
  disko.devices.disk.workspace = {
    device = "/dev/disk/by-id/ata-WDC_WDS200T2G0A-00JH30_232472440915";
    type = "disk";
    content = {
      type = "gpt";
      partitions.data = {
        size = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/workspace";
          mountOptions = ["noatime"];
        };
      };
    };
  };
}
