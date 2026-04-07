{
  pkgs,
  lib,
  config,
  agenix,
  ...
}: let
  packages = config.core.nixPackages;
  user = config.core.username;
  hostname = config.core.hostname;
  system = pkgs.stdenv.hostPlatform.system;
in {
  environment.systemPackages =
    packages
    ++ [
      agenix.packages.${system}.default
    ];

  programs.zsh.enable = true;

  users.users.${user} = {
    name = "${user}";
    home =
      if pkgs.stdenv.hostPlatform.isDarwin
      then "/Users/${user}"
      else "/home/${user}";
    shell = pkgs.zsh;
  };

  networking =
    {
      hostName = hostname;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      computerName = hostname;
    };

  nixpkgs.config = {
    allowUnfree = true;
  };

  time.timeZone =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Asia/Calcutta"
    else "Asia/Kolkata";

  nix =
    {
      enable =
        if pkgs.stdenv.hostPlatform.isDarwin
        then false
        else true;
      package = pkgs.nix;
      settings = {
        sandbox = false;
        trusted-users = [
          "@admin"
          user
        ];
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
        ];
        trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
      };
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    }
    // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

  environment.shellInit = builtins.readFile ../../../nixos/files/shell_functions.sh;

  system.stateVersion = "25.11";
}
