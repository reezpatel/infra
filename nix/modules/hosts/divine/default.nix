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
      base
      desktop

      # Features
      nvidia
      gpu-handover

      samba
      helium
      gui-common
      windows-apps
      gaming
      mac-keyboard
      ollama

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
        networking.firewall.allowedTCPPorts = [5173
        5174
        5175
        5176
        5177];


        # Pin KWin to the RTX 5050 so the 3090 stays completely free for
        # compute (and VM handover). NVIDIA->NVIDIA cross-GPU PRIME copies are
        # broken in the driver (known upstream bug: "Failed to import NVKMS
        # memory to GEM object" in nvidia-drm), which made outputs on the
        # second GPU flicker - so both monitors must be plugged into the 5050.
        #
        # KWIN_DRM_DEVICES is a colon-separated list, so the /dev/dri/by-path
        # PCI symlink (which contains ':') cannot be used directly - the udev
        # rule below creates a colon-free stable alias for the 5050 instead.
        # NOTE: ID_PATH is slot-dependent - if the 5050 moves to another slot,
        # the address must be updated (it was 0d:00.0 in an earlier slot,
        # 0e:00.0 now).
        services.udev.extraRules = ''
          SUBSYSTEM=="drm", KERNEL=="card[0-9]", ENV{ID_PATH}=="pci-0000:0e:00.0", SYMLINK+="dri/kwin-card"
        '';
        environment.sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/kwin-card";
        programs.niri.enable = true;
        macKeyboard.enable = true;
        windowsApps.enable = true;
        gaming.enable = true;
        kicad.enable = true;

        # Dynamic GPU/Thunderbolt handover to the Windows VM (NOT static
        # passthrough - host keeps the devices until `virsh start win11`).
        gpuHandover = {
          enable = true;
          vmName = "win11";

          # Display service stopped before the GPU is unbound and restarted
          # after the VM exits (display-manager.service aliases whichever DM
          # is active - sddm here).
          displayManagerService = "display-manager.service";

          # RTX 3090 + HDMI/DP audio function (confirmed via lspci)
          gpuPciAddress = "0000:01:00.0";
          gpuAudioPciAddress = "0000:01:00.1";

          # Host desktop runs ON the 3090: starting the VM stops the niri
          # session, hands the 3090 to Windows (use a monitor on the 3090's
          # outputs), and on VM shutdown greetd auto-logs back into niri.
          #
          # No PCI handover besides the GPU - mouse/keyboard/speaker are
          # plain USB hostdevs in win11.xml (auto-attach/detach with the VM).
          servicesToStop = [
            "ollama.service"
            "docker.service"
          ];

          # 64 GiB for the VM (allocated only while it runs)
          hugepagesGB = 64;
        };

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
