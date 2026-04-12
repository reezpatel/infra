{...}: let
  commonPackagesModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      age
      bat
      curl
      eza
      fd
      fzf
      jq
      ripgrep
      tree
      vim
      wget
      autoenv
      nix-update
      nh
      just
      nushell
    ];
  };
in {
  moduleRegistry.darwin.commonPackages = commonPackagesModule;
  moduleRegistry.nixos.commonPackages = commonPackagesModule;
}
