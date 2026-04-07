{
  config,
  lib,
  pkgs,
  ...
}:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    enable = config.core.enableGpu;
  };

  services.xserver.videoDrivers = lib.mkIf config.core.enableGpu ["nvidia"];
}
