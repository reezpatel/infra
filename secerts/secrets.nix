let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8";
  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhPJ2G4JeyE5Dk/IR3bU/XsxpySTn47UPhnvdUpPSd8";

  vixen = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7s63dj6iFQWPXx7fue8u20uBGhNPuQa42BkOAfHV5A";
  divine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9ksh2iBB268LT9xO88448WRKcAd7GzPb3Zc02tQKAv";
  luffy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7AvUYoeuj82EzveXi06zzDRgBiJujjpVbx+QIbPtfI";
  slayer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOG1dd9Q7e5QCDmRFa3DWIVqZ9Be1Qb9eVRuhmvTIxy";
  trinity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETXT7s+DJrxDs0dViz8V7S3zJD2xFquVPMi3zLpIw5x";

  rpi1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmkHvuXuPmQDnsmGrPRF03iDHRKU7nL4Me8G3189b9o";
  rpi2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDOKB6C/gz8j0HTmNCvww2K7eigZ3kdAxMtQktaRIZd";
  rpi3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuqEXwtdeVgAP0K5o6GgG59JtdEIXf2f1hL/8VyZIUo";
  rpi4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAqkWdBFrOWfh8TDHfuMcQg/SfNBEHc1YGbQoiWsHLz";
  rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1Cvn5MJCIRlirTQR3Yv+KlquhPS6zEvPGsm7EB225X";

  ace = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfv3oPAe0bdMnsugwBFkLPXgmIZDcluTcQjid6yOb+x";

  all = [
    user1
    system1
    vixen
    divine
    luffy
    slayer
    trinity
    rpi1
    rpi2
    rpi3
    rpi4
    rpi5
    ace
  ];
in {
  "dev-rsa.age".publicKeys = all;
  "ppd-rsa.age".publicKeys = all;
  "private-func.age".publicKeys = all;
  "samba-password.age".publicKeys = all;
  "stash-jwt-key.age".publicKeys = all;
  "stash-session-key.age".publicKeys = all;
  "stash-password.age".publicKeys = all;
  "forgejo-runner-token.age".publicKeys = all;
  "forgejo-password.age".publicKeys = all;
  "frp-token.age".publicKeys = all;
  "headscale-auth-key.age".publicKeys = all;
  "webdav-password.age".publicKeys = all;
  "opencode-auth.age".publicKeys = all;

  "grafana-secret-key.age".publicKeys = all;
  "grafana-admin-password.age".publicKeys = all;
  "home-assistant-token.age".publicKeys = all;
  "jellyfin-api-key.age".publicKeys = all;
  "rustdesk-id-ed25519.age".publicKeys = all;
}
