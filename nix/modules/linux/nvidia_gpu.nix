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

    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };

    environment.systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      cudaPackages.cuda_nvcc # NVCC compiler

      cudaPackages.tensorrt
      # python3Packages.torch-bin # PyTorch with CUDA (pre-built binary wheel)
      # python3Packages.tensorflow-bin # TensorFlow with CUDA
      # opencv # OpenCV (CUDA-enabled build from Flox cache)

      nvtopPackages.full # GPU process monitor (like htop for GPU)
      pciutils # lspci
      linuxPackages.perf
    ];

    environment.variables = {
      CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cudnn
        "/run/opengl-driver/lib" # NVIDIA OpenGL / Vulkan ICD
      ];
      XLA_FLAGS = "--xla_gpu_cuda_data_dir=${pkgs.cudaPackages.cudatoolkit}";
    };

    nixpkgs.config.cudaSupport = true;
  };
}
