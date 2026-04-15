{...}: {
  moduleRegistry.nixos.nvidia_gpu = {
    config,
    lib,
    pkgs,
    ...
  }: {
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

    environment.systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.cuda_nvcc
      cudaPackages.nccl
      cudaPackages.libcusparse_lt

      nvtopPackages.full
      pciutils
      linuxPackages.perf
      ninja
      pkgs.libGL
    ];

    environment.variables = {
      CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cudnn
        pkgs.cudaPackages.nccl
        pkgs.cudaPackages.libcusparse_lt
        pkgs.stdenv.cc.cc.lib
        pkgs.libGL
        "/run/opengl-driver"
      ];
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}";
    };

    nixpkgs.config.cudaSupport = true;
  };
}
