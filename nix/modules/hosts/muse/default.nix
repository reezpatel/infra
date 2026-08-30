# muse — NAS/media server (mergerfs + snapraid), KDE workstation.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.muse = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      # Aspects
      server
      home

      # Features
      nvidia
      samba
      kde

      # Host-specific
      inputs.disko.nixosModules.disko
      ./_disko.nix
      ./_hardware-configuration.nix
      ./_storage.nix

      # Identity
      ({config, ...}: {
        hostname = "muse";

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
          nvim
          runtimes
          devops
          ollama
        ];
      })
    ];
  };
}
