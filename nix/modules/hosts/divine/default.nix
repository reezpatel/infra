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

        # Run KWin on the RTX 5050 so the RTX 3090 stays available for CUDA
        # and can later be handed to the Windows VM. Both monitors must be
        # connected to the 5050's outputs.
        #
        # KWIN_DRM_DEVICES is a colon-separated list, so the /dev/dri/by-path
        # PCI symlink (which contains ':') cannot be used directly - the udev
        # rule below creates a colon-free stable alias for the 5050 instead.
        # NOTE: ID_PATH is slot-dependent - update this if the 5050 moves.
        #
        # Lessons from debugging (2026-09):
        # - Do NOT point this at the 3090 as an experiment: KWin's saved
        #   output config drives the 3090's monitor at 4K@120 HDR, whose FRL
        #   link training fails; KWin then loses its only device ("no
        #   outputs") and the session dies to a blank screen.
        # - The 5050's 4K monitor declares MaxTMDS=280MHz in its EDID, so
        #   4K@60 REQUIRES HDMI 2.1 FRL. FRL @ 6G/lane is cable-sensitive:
        #   a marginal cable shows up as intermittent black screens with
        #   "nvidia-modeset: WARNING: GPU:x: HDMI FRL link training failed"
        #   in the kernel log. Use a certified Ultra High Speed HDMI cable.
        services.udev.extraRules = ''
          SUBSYSTEM=="drm", KERNEL=="card[0-9]", ENV{ID_PATH}=="pci-0000:0e:00.0", SYMLINK+="dri/kwin-card"
        '';
        environment.sessionVariables = {
          KWIN_DRM_DEVICES = "/dev/dri/kwin-card";
        };

        # TODO: dynamic RTX 3090 (+ 0000:01:00.1 audio) handover to the
        # Windows VM (win11.xml). Desktop runs on the 5050, so unbinding the
        # 3090 won't disturb the display session - only CUDA users of the
        # 3090 (ollama, docker) need stopping while the VM runs.

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
