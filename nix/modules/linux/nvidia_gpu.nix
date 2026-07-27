{...}: {
  moduleRegistry.nixos.nvidia_gpu = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.nvidiaGpu;
  in {
    options.nvidiaGpu.enableCuda = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install CUDA packages and enable nixpkgs CUDA support.";
    };

    config = {
      hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;

        modesetting.enable = true;
        open = false;
        nvidiaSettings = true;
      };

      services.xserver.videoDrivers = ["nvidia"];

      boot.kernelModules = ["nvidia" "nvidia_uvm" "nvidia_drm" "nvidia_modeset"];
      boot.blacklistedKernelModules = ["nouveau" "nvidiafb"];
      boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
        ];
      };

      environment.systemPackages = with pkgs;
        [
          nvtopPackages.full
          pciutils
          perf
          ninja
          pkgs.libGL
        ]
        ++ lib.optionals cfg.enableCuda [
          cudaPackages.cudatoolkit
          cudaPackages.cudnn
          cudaPackages.cuda_nvcc
          cudaPackages.nccl
          cudaPackages.libcusparse_lt
        ];

      environment.variables =
        {
          LD_LIBRARY_PATH = lib.makeLibraryPath (
            [
              pkgs.stdenv.cc.cc.lib
              pkgs.libGL
              "/run/opengl-driver"
            ]
            ++ lib.optionals cfg.enableCuda [
              pkgs.cudaPackages.cudatoolkit
              pkgs.cudaPackages.cudnn
              pkgs.cudaPackages.nccl
              pkgs.cudaPackages.libcusparse_lt
            ]
          );
        }
        // lib.optionalAttrs cfg.enableCuda {
          CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
          XLA_FLAGS = "--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}";
        };

      nixpkgs.config.cudaSupport = cfg.enableCuda;
    };
  };
}
