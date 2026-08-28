{...}: {
  # Dynamic GPU / PCI handover for a libvirt Windows VM.
  #
  # Unlike static VFIO passthrough (vfio-pci.ids=..., video=efifb:off), the
  # devices stay bound to their host drivers at boot. A libvirt qemu hook
  # rebinds them to vfio-pci when the VM starts and hands them back to the
  # host (nvidia, thunderbolt, desktop session, services) when it stops.
  moduleRegistry.nixos.gpu_handover = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.gpuHandover;

    inherit
      (lib)
      mkEnableOption
      mkOption
      mkIf
      types
      concatStringsSep
      optionalString
      reverseList
      ;

    gpuDevices =
      [cfg.gpuPciAddress]
      ++ lib.optional (cfg.gpuAudioPciAddress != null) cfg.gpuAudioPciAddress;

    hook = pkgs.writeShellScript "libvirt-qemu-gpu-handover" ''
      export PATH="${lib.makeBinPath [pkgs.coreutils pkgs.kmod pkgs.psmisc pkgs.systemd]}:$PATH"

      GUEST="$1"
      OP="$2"
      SUB="$3"

      LOG=/var/log/libvirt/gpu-handover.log
      log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

      # Only manage the handover VM
      [ "$GUEST" = "${cfg.vmName}" ] || exit 0

      GPU_DEVICES="${concatStringsSep " " gpuDevices}"
      TB_DEVICES="${concatStringsSep " " cfg.thunderboltPciAddresses}"

      bind_vfio() {
        dev="$1"
        if [ ! -e "/sys/bus/pci/devices/$dev" ]; then
          log "WARNING: $dev does not exist, skipping"
          return
        fi
        log "binding $dev -> vfio-pci"
        echo vfio-pci > "/sys/bus/pci/devices/$dev/driver_override"
        if [ -L "/sys/bus/pci/devices/$dev/driver" ]; then
          echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind" || true
          for _ in $(seq 1 50); do
            [ ! -L "/sys/bus/pci/devices/$dev/driver" ] && break
            sleep 0.1
          done
        fi
        echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
      }

      release_vfio() {
        dev="$1"
        [ -e "/sys/bus/pci/devices/$dev" ] || return
        log "releasing $dev from vfio-pci"
        if [ -L "/sys/bus/pci/devices/$dev/driver" ]; then
          echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind" || true
        fi
        echo "" > "/sys/bus/pci/devices/$dev/driver_override" || true
      }

      if [ "$OP" = "prepare" ] && [ "$SUB" = "begin" ]; then
        log "=== handover begin: $GUEST ==="

        modprobe vfio
        modprobe vfio_iommu_type1
        modprobe vfio_pci

        ${optionalString (cfg.displayManagerService != null) ''
          # Stop the desktop session so it releases the GPU
          systemctl stop ${cfg.displayManagerService} || true
          log "stopped display manager (${cfg.displayManagerService})"
        ''}

        # Stop services that may hold the GPU or the thunderbolt controller
        for svc in ${concatStringsSep " " cfg.servicesToStop}; do
          systemctl stop "$svc" 2>/dev/null || true
        done

        sleep 2
        # Kill anything still holding the dGPU. NOTE: deliberately NOT
        # touching /dev/dri/* here - with an iGPU host, the compositor holds
        # those nodes and must keep running.
        fuser -k /dev/nvidia* 2>/dev/null || true
        sleep 1

        # Unload the host GPU driver (retry while userspace lets go of it)
        for i in $(seq 1 20); do
          if modprobe -r ${concatStringsSep " " cfg.hostGpuModules} 2>>"$LOG"; then
            log "host GPU driver unloaded (attempt $i)"
            break
          fi
          sleep 1
        done

        # Hand devices over to vfio
        for dev in $GPU_DEVICES $TB_DEVICES; do
          bind_vfio "$dev"
        done

        ${optionalString (cfg.hugepagesGB > 0) ''
          # Allocate hugepages for the VM (freed again on release)
          pages=$(( ${toString cfg.hugepagesGB} * 512 ))
          echo "$pages" > /proc/sys/vm/nr_hugepages
          log "hugepages: requested $pages, allocated $(cat /proc/sys/vm/nr_hugepages)"
        ''}
      fi

      if [ "$OP" = "release" ] && [ "$SUB" = "end" ]; then
        log "=== handover end: $GUEST ==="

        ${optionalString (cfg.hugepagesGB > 0) ''
          echo 0 > /proc/sys/vm/nr_hugepages || true
        ''}

        # Take devices back from vfio
        for dev in $GPU_DEVICES $TB_DEVICES; do
          release_vfio "$dev"
        done

        # Reload host drivers - they auto-bind unbound devices they support
        ${optionalString (cfg.thunderboltPciAddresses != []) "modprobe thunderbolt || true"}
        ${concatStringsSep "\n" (map (m: "modprobe ${m} || true") (reverseList cfg.hostGpuModules))}

        # Fallback: force a modalias reprobe for anything still unbound
        for dev in $GPU_DEVICES $TB_DEVICES; do
          if [ -e "/sys/bus/pci/devices/$dev" ] && [ ! -L "/sys/bus/pci/devices/$dev/driver" ]; then
            echo "$dev" > /sys/bus/pci/drivers_probe || true
          fi
        done

        # Restart services and the desktop session
        for svc in ${concatStringsSep " " (reverseList cfg.servicesToStop)}; do
          systemctl start "$svc" 2>/dev/null || true
        done
        ${optionalString (cfg.displayManagerService != null) "systemctl start ${cfg.displayManagerService} || true"}

        log "handover complete, host restored"
      fi

      exit 0
    '';
  in {
    options.gpuHandover = {
      enable = mkEnableOption "dynamic GPU/PCI handover to a libvirt Windows VM";

      vmName = mkOption {
        type = types.str;
        default = "win11";
        description = "libvirt domain name whose start/stop triggers the handover.";
      };

      gpuPciAddress = mkOption {
        type = types.str;
        default = "0000:01:00.0";
        description = "PCI address of the GPU (check with `lspci -nn`).";
      };

      gpuAudioPciAddress = mkOption {
        type = types.nullOr types.str;
        default = "0000:01:00.1";
        description = "PCI address of the GPU HDMI/DP audio function (usually in the same IOMMU group).";
      };

      hostGpuModules = mkOption {
        type = types.listOf types.str;
        default = ["nvidia_drm" "nvidia_modeset" "nvidia_uvm" "nvidia"];
        description = "Host GPU kernel modules, in unload order (reversed on restore).";
      };

      thunderboltPciAddresses = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["0000:0c:00.0"];
        description = ''
          PCI addresses of Thunderbolt/USB4 host controllers handed to the VM.
          Find them with `lspci -nn | grep -i thunderbolt`.
        '';
      };

      displayManagerService = mkOption {
        type = types.nullOr types.str;
        default = "greetd.service";
        description = ''
          systemd unit for the desktop session, stopped before the GPU is
          unbound and restarted after the VM exits. Set to null when the
          host desktop runs on an iGPU/second GPU and must stay alive
          during handover.
        '';
      };

      servicesToStop = mkOption {
        type = types.listOf types.str;
        default = ["ollama.service" "docker.service" "bolt.service"];
        description = "Services stopped while the VM owns the devices (GPU compute, boltd, ...).";
      };

      hugepagesGB = mkOption {
        type = types.int;
        default = 16;
        description = ''
          GiB of 2 MiB hugepages dynamically allocated when the VM starts and
          freed when it stops. Set to 0 to disable (then drop <hugepages/>
          from the domain XML memoryBacking).
        '';
      };

      iommuKernelParams = mkOption {
        type = types.listOf types.str;
        default = ["amd_iommu=on" "iommu=pt"];
        description = "Kernel parameters enabling IOMMU (use intel_iommu=on on Intel).";
      };

      lookingGlass = {
        enable = mkEnableOption ''
          Looking Glass shared-memory framebuffer. Only useful if an
          iGPU/second GPU keeps driving the host desktop while the VM owns
          the dGPU - with a single GPU the host has nothing to display the
          client on during handover.
        '';
        sizeMB = mkOption {
          type = types.int;
          default = 128;
          description = "kvmfr static shared memory size in MiB (128 MiB covers 4K).";
        };
      };
    };

    config = mkIf cfg.enable {
      # IOMMU on, in passthrough mode for host drivers.
      # NOTE: deliberately NO vfio-pci.ids= and NO video=efifb:off here -
      # this is handover, the host keeps using the GPU until the VM starts.
      boot.kernelParams = cfg.iommuKernelParams;

      # VFIO available early, but bound to nothing at boot.
      boot.initrd.kernelModules = ["vfio_pci" "vfio" "vfio_iommu_type1"];

      virtualisation.libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
        # Native qemu.d hook support (libvirt >= 10.5). Runs as root for
        # every qemu domain; the script itself filters on cfg.vmName.
        hooks.qemu."50-gpu-handover" = hook;
      };

      users.users.${config.username}.extraGroups = ["libvirtd" "kvm"];

      # Plain `virsh` should talk to the system daemon, not qemu:///session
      environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

      programs.virt-manager.enable = true;

      environment.systemPackages = with pkgs;
        [
          virt-viewer
          virtio-win # extracted driver tree; ISO exposed below
          pciutils
        ]
        ++ lib.optional cfg.lookingGlass.enable pkgs.looking-glass-client;

      # virtio driver ISO at a stable path for VM XMLs to reference
      environment.etc."virtio/virtio-win.iso".source = pkgs.virtio-win.src;

      # Looking Glass kernel module (see option description for the caveat)
      boot.kernelModules = lib.optional cfg.lookingGlass.enable "kvmfr";
      boot.extraModulePackages = lib.optional cfg.lookingGlass.enable config.boot.kernelPackages.kvmfr;
      boot.extraModprobeConfig = optionalString cfg.lookingGlass.enable ''
        options kvmfr static_size_mb=${toString cfg.lookingGlass.sizeMB}
      '';
      systemd.tmpfiles.rules = lib.optional cfg.lookingGlass.enable
        "f /dev/shm/looking-glass 0660 ${config.username} kvm ${toString cfg.lookingGlass.sizeMB}M";
      services.udev.extraRules = optionalString cfg.lookingGlass.enable ''
        KERNEL=="kvmfr0", OWNER="${config.username}", GROUP="kvm", MODE="0660"
      '';
    };
  };
}
