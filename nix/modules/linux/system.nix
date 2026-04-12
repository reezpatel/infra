{...}: {
  moduleRegistry.nixos.system = {
    pkgs,
    config,
    ...
  }: {
    nix = {
      enable =
        if pkgs.stdenv.hostPlatform.isDarwin
        then false
        else true;
      package = pkgs.nix;
      settings = {
        sandbox = false;
        trusted-users = [
          "@admin"
          config.username
        ];
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
          "https://cache.flox.dev"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        ];
      };
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    time.timeZone = "Asia/Kolkata";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;

    networking.networkmanager.enable = true;
    networking.firewall.enable = false;
    services.resolved.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        userServices = true;
      };
    };

    boot.kernelParams = [
      "cgroup_memory=1"
      "cgroup_enable=memory"
    ];

    boot.kernelModules = ["ntsync"];

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        X11Forwarding = true;
        StreamLocalBindUnlink = "yes";
      };
    };

    programs.fuse.userAllowOther = true;

    systemd.tmpfiles.rules = [
      "d /home/${config.username}/.local/share/tmux 0700 ${config.username} users -"
    ];

    users.users.root = {
      initialPassword = "nixos";
      openssh.authorizedKeys.keys = config.authorizedKeys;
    };

    users.users.${config.username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keys = config.authorizedKeys;
    };
  };
}
