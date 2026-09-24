let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8";
  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhPJ2G4JeyE5Dk/IR3bU/XsxpySTn47UPhnvdUpPSd8";

  vixen = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7s63dj6iFQWPXx7fue8u20uBGhNPuQa42BkOAfHV5A";
  divine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9ksh2iBB268LT9xO88448WRKcAd7GzPb3Zc02tQKAv";
  luffy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7AvUYoeuj82EzveXi06zzDRgBiJujjpVbx+QIbPtfI";
  slayer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcq+2xoMBxwrYB/7TL2C9TpdNBeAjSfnthTsaK8MVDk";
  trinity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETXT7s+DJrxDs0dViz8V7S3zJD2xFquVPMi3zLpIw5x";

  rpi1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDmkHvuXuPmQDnsmGrPRF03iDHRKU7nL4Me8G3189b9o";
  rpi2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDOKB6C/gz8j0HTmNCvww2K7eigZ3kdAxMtQktaRIZd";
  rpi3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuqEXwtdeVgAP0K5o6GgG59JtdEIXf2f1hL/8VyZIUo";
  rpi4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAqkWdBFrOWfh8TDHfuMcQg/SfNBEHc1YGbQoiWsHLz";
  rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1Cvn5MJCIRlirTQR3Yv+KlquhPS6zEvPGsm7EB225X";

  ace = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfv3oPAe0bdMnsugwBFkLPXgmIZDcluTcQjid6yOb+x";
  divergent = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJCrqSJN0GPdR8FUYsBNmexaOu/+D8Rmx19nIhZE6jq";

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
    divergent
  ];
in
{
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
  "webdav-password.age".publicKeys = all;
  "opencode-auth.age".publicKeys = all;

  # NetBird (mesh clients + control plane on slayer)
  "netbird-setup-key.age".publicKeys = all;
  "netbird-management-encryption-key.age".publicKeys = [
    user1
    system1
    slayer
  ];
  "netbird-turn-secret.age".publicKeys = [
    user1
    system1
    slayer
  ];
  "netbird-turn-password.age".publicKeys = [
    user1
    system1
    slayer
  ];
  "pocket-id-encryption-key.age".publicKeys = [
    user1
    system1
    slayer
  ];

  # TwoDB node agents — per-machine tokens from Settings → Machines in the
  # twodb web UI (server on slayer). Placeholders until re-encrypted with
  # the real token: agenix -e secerts/twodb-node-token-<host>.age
  "twodb-node-token-trinity.age".publicKeys = [
    user1
    system1
    trinity
  ];
  "twodb-node-token-divergent.age".publicKeys = [
    user1
    system1
    divergent
  ];
  "twodb-node-token-divine.age".publicKeys = [
    user1
    system1
    divine
  ];
  "twodb-node-token-vixen.age".publicKeys = [
    user1
    system1
    vixen
  ];
  "twodb-node-token-ace.age".publicKeys = [
    user1
    system1
    ace
  ];
  "twodb-node-token-luffy.age".publicKeys = [
    user1
    system1
    luffy
  ];
  "twodb-node-token-rpi1.age".publicKeys = [
    user1
    system1
    rpi1
  ];
  "twodb-node-token-rpi2.age".publicKeys = [
    user1
    system1
    rpi2
  ];
  "twodb-node-token-rpi3.age".publicKeys = [
    user1
    system1
    rpi3
  ];
  "twodb-node-token-rpi4.age".publicKeys = [
    user1
    system1
    rpi4
  ];
  "twodb-node-token-rpi5.age".publicKeys = [
    user1
    system1
    rpi5
  ];
  # muse/rpi6/rpi7: real tokens already encrypted (to user1+system1 only),
  # but their SSH host keys aren't registered above yet. Once each key is
  # added (as a `muse`/`rpi6`/`rpi7` let-binding at the top + a recipient
  # below): cd secerts && agenix -r   → rekeys to the host, then enable
  # twodb-node in the host's modules and deploy.
  "twodb-node-token-muse.age".publicKeys = [
    user1
    system1
  ];
  "twodb-node-token-rpi6.age".publicKeys = [
    user1
    system1
  ];
  "twodb-node-token-rpi7.age".publicKeys = [
    user1
    system1
  ];

  "grafana-secret-key.age".publicKeys = all;
  "grafana-admin-password.age".publicKeys = all;
  "home-assistant-token.age".publicKeys = all;
  "jellyfin-api-key.age".publicKeys = all;
  "rustdesk-id-ed25519.age".publicKeys = all;
  "secrets.age".publicKeys = all;
}
