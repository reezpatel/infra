# mergerfs pool for divine (2 data disks, no snapraid).
{...}: {
  fileSystems."/mnt/mergefs" = {
    device = "/mnt/weed/sda:/mnt/weed/sdb";
    fsType = "fuse.mergerfs";
    options = [
      "defaults"
      "nofail"
      "allow_other"
      "use_ino"
      "cache.files=partial"
      "dropcacheonclose=true"
      "category.create=mfs" # place new files on disk with most free space
    ];
  };
}
