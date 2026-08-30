{...}: {
  disko.devices = {
    disk = {
      # HDD — separate disks, combined via mergerfs
      weed-sda = {
        device = "/dev/disk/by-id/wwn-0x5000c500e06261ee"; # 7.3T Seagate
        type = "disk";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/weed/sda";
              mountOptions = ["noatime" "nofail"];
            };
          };
        };
      };
      weed-sdb = {
        device = "/dev/disk/by-id/wwn-0x5000c500e50dae84"; # 10.9T Seagate
        type = "disk";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/weed/sdb";
              mountOptions = ["noatime" "nofail"];
            };
          };
        };
      };

      # SSD — RAID 1 (mirror) members
      ssd-sdc = {
        device = "/dev/disk/by-id/wwn-0x5001b448b28a43d9"; # 1.8T WDC
        type = "disk";
        content = {
          type = "gpt";
          partitions.raid = {
            size = "1800G";
            content = {
              type = "mdraid";
              name = "raid1-ssd";
            };
          };
        };
      };
      ssd-sdd = {
        device = "/dev/disk/by-id/ata-EVM_SSD_AA000000000000000020"; # 1.9T EVM
        type = "disk";
        content = {
          type = "gpt";
          partitions.raid = {
            size = "1800G";
            content = {
              type = "mdraid";
              name = "raid1-ssd";
            };
          };
        };
      };

      # NVMe — unchanged
      nvme1 = {
        device = "/dev/disk/by-id/nvme-KINGSTON_SNV3S2000G_50026B738363AF62";
        type = "disk";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/nvme1";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };

    mdadm = {
      raid1-ssd = {
        type = "mdadm";
        level = 1;
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/ssd";
              mountOptions = ["noatime" "nofail"];
            };
          };
        };
      };
    };
  };
}
