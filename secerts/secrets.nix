let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8";
  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhPJ2G4JeyE5Dk/IR3bU/XsxpySTn47UPhnvdUpPSd8";

  vixen = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH7s63dj6iFQWPXx7fue8u20uBGhNPuQa42BkOAfHV5A";
  divine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9ksh2iBB268LT9xO88448WRKcAd7GzPb3Zc02tQKAv";
  luffy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7AvUYoeuj82EzveXi06zzDRgBiJujjpVbx+QIbPtfI";
  all = [
    user1
    system1
    vixen
    divine
    luffy
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

  "armored-secret.age" = {
    publicKeys = all;
    armor = true;
  };
}
