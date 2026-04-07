{
  lib,
  pkgs,
  config,
  ...
}:
let
  user = config.core.username;
  authorizedKeys = config.core.authorizedKeys;
in
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;

    networking.networkmanager.enable = true;
    networking.firewall.enable = false;
    services.resolved.enable = true;

    boot.kernelParams = [
      "cgroup_memory=1"
      "cgroup_enable=memory"
    ];

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    users.users.root = {
      initialPassword = "nixos";
      openssh.authorizedKeys.keys = authorizedKeys;
    };

    users.users.${user} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = authorizedKeys;
    };
  };
}
