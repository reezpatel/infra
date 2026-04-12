{ ... }:
{

  disko.devices.disk = {
    weed-sdb = {
      device = "/dev/disk/by-id/wwn-0x50014ee216940c74";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sdb";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
    weed-sdc = {
      device = "/dev/disk/by-id/wwn-0x50014ee216940d48";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sdc";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
    weed-sdd = {
      device = "/dev/disk/by-id/wwn-0x50014ee216940cde";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sdd";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
    weed-sde = {
      device = "/dev/disk/by-id/wwn-0x50014ee216940c50";
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/mnt/weed/sde";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };
}
