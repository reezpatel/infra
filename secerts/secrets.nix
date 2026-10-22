let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8";
  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhPJ2G4JeyE5Dk/IR3bU/XsxpySTn47UPhnvdUpPSd8";

  vixen = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7s63dj6iFQWPXx7fue8u20uBGhNPuQa42BkOAfHV5A";
  divine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9ksh2iBB268LT9xO88448WRKcAd7GzPb3Zc02tQKAv";
  luffy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7AvUYoeuj82EzveXi06zzDRgBiJujjpVbx+QIbPtfI";
  slayer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcq+2xoMBxwrYB/7TL2C9TpdNBeAjSfnthTsaK8MVDk";
  trinity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHIG8bZ8l2+scXENBHqLDaSqUWerl3yylUoTy6iSh87";

  rpi1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMW+jVaH/CTeLW+F2gP4dskl99G77JEH/yjT/+WhRHVo";
  rpi2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYJ/TR5rzkLd+exqX0Cc+DN2tUAHpRfs1/2YkfR4PXO";
  rpi3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXpSE3oy/yGyPjGyAYAxD5xpfTsqK8oY3L9gVs6Mhlf";
  rpi4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKRuDRGTyWdDKpLRWSaigxRBys6v2KX++gBdq/7G82Kx";
  rpi5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpenGWpYDxkqDK7+20aPu1Q8Q4gaQA5hBiiSZ8tLx1f";
  rpi6 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtn8IWY7V+CGQU2icQwcg9B59cPRheW0eOaL09pQ0Gj";

  ace = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9wquTRSKBWywElJnndnbzNTnRcVLYCWCOOUlooAWCC";
  divergent = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJCrqSJN0GPdR8FUYsBNmexaOu/+D8Rmx19nIhZE6jq";
  atomata = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/Bro4DGNIOzffDNTA05+H2FsXg77251+r7Bm//qfGm";

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
    rpi6
    ace
    divergent
    atomata
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

  # TwoDB server environment (BETTER_AUTH_SECRET) — consumed via
  # environmentFile by the native twodb-server systemd unit on slayer.
  "twodb-server-env.age".publicKeys = [
    user1
    slayer
  ];

  # TwoDB runner — ONE shared access key for all runners (Settings →
  # Runners in the twodb web UI, server on slayer). Replaces the old
  # per-machine twodb-node tokens. Rotate: agenix -e secerts/twodb-runner-key.age
  "twodb-runner-key.age".publicKeys = [
    user1
    system1
    vixen
    divine
    luffy
    trinity
    divergent
    ace
    atomata
    rpi1
    rpi2
    rpi3
    rpi4
    rpi5
  ];

  # Netboot fleet push key — private half lives on the netbooted Pis
  # (agenix), public half in netboot-server.pushAuthorizedKeys on
  # divergent. Used by rpi-netboot's netboot-boot-push to upload each
  # node's own kernel/initrd/boot config to the TFTP tree.
  "netboot-push-key.age".publicKeys = [
    user1
    system1
    rpi1
    rpi2
    rpi3
    rpi4
    rpi5
    rpi6
  ];

  "grafana-secret-key.age".publicKeys = all;
  "grafana-admin-password.age".publicKeys = all;
  "home-assistant-token.age".publicKeys = all;
  "jellyfin-api-key.age".publicKeys = all;
  "rustdesk-id-ed25519.age".publicKeys = all;
  "secrets.age".publicKeys = all;
}
