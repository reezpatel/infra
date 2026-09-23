{...}: {
  disko.devices.disk.workspace = {
    device = "/dev/disk/by-id/nvme-INTEL_SSDPEKNW020T8_BTNH93650N122P0C";
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
