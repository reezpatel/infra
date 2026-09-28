# divine — primary workstation: niri desktop, CUDA dev, GPU/Thunderbolt
# handover to a Windows VM, embedded/hardware tooling.
{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.divine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with self.modules.nixos; [
      workstation
      samba
      twodb-runner

      # Host-specific
      inputs.disko.nixosModules.disko
      ./_disko.nix
      ./_hardware-configuration.nix

      ./_storage.nix
      ./_desktop.nix
      ./_pkgs.nix
      (import ./_home.nix { inherit inputs self; })

      # Identity + feature configuration
      ({ ... }: {
        nixpkgs.overlays = [
          (_final: prev: {
            nrfutil = prev.nrfutil.override {
              versionCheckHook = prev.emptyDirectory;
            };
          })
        ];
        hostname = "divine";
        nvidiaGpu.enableCuda = true;
        networking.firewall.allowedTCPPorts = [
          5173
          5174
          5175
          5176
          5177
        ];

        # GPU/display pinning for KWin lives in ./_desktop.nix.

        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;
        services.hardware.bolt.enable = true;
        services.gvfs.enable = true;
        services.udisks2.enable = true;
        services.printing.enable = true;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
        hardware.bluetooth.enable = true;

        # Disable systemd-oomd to prevent aggressive process killing
        # (especially problematic without swap configured)
        systemd.oomd.enable = false;
      })
    ];
  };
}
