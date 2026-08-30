{ ... }: {
  flake.modules.nixos.system =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.segger-jlink.acceptLicense = true;

      nix = {
        enable = true;
        package = pkgs.nix;
        settings = {
          sandbox = false;
          trusted-users = [
            "@admin"
            config.username
          ];
          substituters = [
            "https://noctalia.cachix.org"
            "https://nix-community.cachix.org"
            "https://cache.nixos.org"
            "https://cache.flox.dev"
          ];
          trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
            # was missing entirely - the nix-community substituter above was
            # silently unused without its key
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
      };

      time.timeZone = "Asia/Kolkata";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = false;
      boot.loader.systemd-boot.configurationLimit = 5;

      networking.networkmanager.enable = true;
      # Firewall ON (default-deny). Every service must declare its ports in
      # its own feature module. The NetBird mesh interface is separately
      # trusted by the netbird-client module.
      networking.firewall.enable = true;
      services.resolved.enable = true;

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        # mDNS (UDP 5353) must pass the firewall for .local resolution
        openFirewall = true;
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

      boot.kernelModules = [ "ntsync" ];

      services.openssh = {
        enable = true;
        # Non-standard port. The openssh module opens these in the firewall
        # automatically (services.openssh.openFirewall defaults to true).
        ports = [ 7272 ];
        settings = {
          # Key-only everywhere: both default keys (MacBook + divine) are
          # installed for the user and root by features/common + this module.
          # PermitRootLogin/X11Forwarding defaults live in linux/hardening.nix.
          PasswordAuthentication = false;
          StreamLocalBindUnlink = "yes";
        };
      };

      # Ban brute-forcers at the firewall; watches the sshd journal
      # (port-agnostic).
      services.fail2ban.enable = true;

      systemd.services.dbus.reloadIfChanged = lib.mkForce false;

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
