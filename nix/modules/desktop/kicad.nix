{...}: {
  flake.modules.nixos.kicad = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.kicad;
  in {
    options.kicad.enable = lib.mkEnableOption "KiCad electronics design suite";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        kicad
      ];
    };
  };
}
