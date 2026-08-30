{lib, ...}: let
  configBuilder = {
    config,
    pkgs,
    ...
  }: {
    options.username = lib.mkOption {
      type = lib.types.str;
      default = "reezpatel";
      description = "Username for the primary user";
    };
    options.hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Hostname for the machine";
    };
    options.authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Authorized SSH keys for the primary user";
    };

    config = {
      users.users.${config.username} = {
        name = "${config.username}";
        home =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "/Users/${config.username}"
          else "/home/${config.username}";
        shell = pkgs.zsh;
      };

      programs.zsh.enable = true;

      # Keys trusted on every host. Plain definition (normal priority) on
      # purpose: list options discard lower-priority groups entirely, so an
      # mkDefault here would silently VANISH the moment any host defines
      # authorizedKeys. At normal priority, host additions concatenate.
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGK+XhnFOsJjoHqNmJ/NMyASsCsz7bkFoj3UpEP0hVQc reezpatel@divine"
      ];

      networking = {
        hostName = config.hostname;
      };

      # Uniform across hosts (nix-darwin's stateVersion is an int and is
      # already set in the darwin macos module, hence the platform check).
      system.stateVersion = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) (lib.mkDefault "26.05");

      nixpkgs.config = {
        allowUnfree = true;
      };

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      environment.pathsToLink = ["/share/zsh"];

      environment.variables = {
        LC_ALL = "en_US.UTF-8";
        LANG = "en_US.UTF-8";
        TMUX_TMPDIR = "/Users/${config.username}/.local/share/tmux";
      };
    };
  };
in {
  flake.modules.darwin.core = configBuilder;
  flake.modules.nixos.core = configBuilder;
}
