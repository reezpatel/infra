# mergerfs pool + snapraid parity for vixen (3 data disks, 1 parity disk).
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mergerfs
    snapraid
  ];

  fileSystems."/mnt/mergefs" = {
    device = "/mnt/weed/sdb:/mnt/weed/sdc:/mnt/weed/sdd";
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

  services.snapraid = {
    enable = true;

    parityFiles = [
      "/mnt/weed/sde/snapraid.parity"
    ];

    # Content files: keep one on parity + one per data disk (redundancy)
    contentFiles = [
      "/var/snapraid.content"
      "/mnt/weed/sde/.snapraid.content"
      "/mnt/weed/sdb/.snapraid.content"
      "/mnt/weed/sdc/.snapraid.content"
      "/mnt/weed/sdd/.snapraid.content"
    ];

    dataDisks = {
      d1 = "/mnt/weed/sdb";
      d2 = "/mnt/weed/sdc";
      d3 = "/mnt/weed/sdd";
    };

    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "downloads/"
      "*.!sync"
    ];

    # Auto-sync schedule (runs nightly at 4am)
    sync.interval = "04:00";

    # Auto-scrub (verify data integrity, runs weekly)
    scrub.interval = "Mon *-*-* 03:00:00";
  };
}
