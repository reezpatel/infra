{...}: {
  moduleRegistry.nixos.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.gaming;
  in {
    options.gaming.enable = lib.mkEnableOption "Linux gaming and Proton tooling";

    config = lib.mkIf cfg.enable {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      programs = {
        gamemode.enable = true;
        steam.enable = true;
      };

      environment.systemPackages = with pkgs; [
        gamescope
        heroic
        lutris
        mangohud
        protontricks
        protonup-qt
      ];
    };
  };
}
