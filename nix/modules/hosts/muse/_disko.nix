{...}: {
  disko.devices.disk = {
    weed-sda = {
      device = "/dev/disk/by-id/wwn-0x5000c500db352c50";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sda";
            mountOptions = ["noatime"];
          };
        };
      };
    };
    weed-sdb = {
      device = "/dev/disk/by-id/wwn-0x5000c500db3573e7";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sdb";
            mountOptions = ["noatime"];
          };
        };
      };
    };
    weed-sdd = {
      device = "/dev/disk/by-id/wwn-0x5000c500e402365d";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sdd";
            mountOptions = ["noatime"];
          };
        };
      };
    };
    weed-sde = {
      device = "/dev/disk/by-id/wwn-0x50014ee269c2a518";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sde";
            mountOptions = ["noatime"];
          };
        };
      };
    };
    weed-sdf = {
      device = "/dev/disk/by-id/wwn-0x5000c500d455752d";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sdf";
            mountOptions = ["noatime"];
          };
        };
      };
    };
  };
}
