# muse — NAS/media server (mergerfs + snapraid), KDE workstation.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.muse = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      server

      # Features
      samba
      kde

      # Services
      twodb-runner
      two-runner

      # Host-specific
      inputs.disko.nixosModules.disko
      ./_disko.nix
      ./_hardware-configuration.nix
      ./_storage.nix

      # Identity
      ({ ... }: {
        hostname = "muse";
        # Host Firecracker microvms for Dispatch (kvm-amd loaded in hardware config).
        services.two-runner.microvm = true;
      })
    ];
  };
}
