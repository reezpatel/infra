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
      nerd-fonts.jetbrains-mono
      nh
      comma
    ];
  };
in {
  flake.modules.darwin.common-packages = commonPackagesModule;
  flake.modules.nixos.common-packages = commonPackagesModule;
}
