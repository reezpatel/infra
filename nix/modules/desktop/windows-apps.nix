{...}: {
  flake.modules.nixos.windows-apps = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.windowsApps;
  in {
    options.windowsApps.enable = lib.mkEnableOption "Windows application compatibility tools";

    config = lib.mkIf cfg.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      environment.systemPackages = with pkgs; [
        cabextract
        dxvk
        icoutils
        mesa-demos
        p7zip
        unzip
        vkd3d-proton
        vulkan-loader
        vulkan-tools
        wineWow64Packages.stagingFull
        winetricks
      ];
    };
  };
}
