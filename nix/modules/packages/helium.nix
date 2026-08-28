{inputs, ...}: {
  moduleRegistry.nixos.helium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
    packages = inputs.helium.packages;
    isSupported = builtins.hasAttr system packages;
    helium = packages.${system}.default;

    # Widevine CDM (Linux only). Helium doesn't ship the unfree CDM. On Linux,
    # Chromium only registers Widevine at startup when it is either bundled
    # next to the binary (not the case for Helium) or "hinted" via a JSON hint
    # file in the user data dir (normally written by the component updater).
    # Write that hint file pointing at the nixpkgs widevine-cdm package.
    # See chrome/common/media/component_widevine_cdm_hint_file_linux.cc
    widevine = pkgs.widevine-cdm;
    widevineDir = "${widevine}/share/google/chrome/WidevineCdm";
  in {
    warnings = lib.optional (!isSupported) ''
      Skipping Helium: no package is defined for ${system}.
    '';

    environment.systemPackages = lib.optionals isSupported [
      helium
    ];

    home-manager.users.${config.username} = lib.mkIf (isSupported && pkgs.stdenv.isLinux) {
      xdg.configFile."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text =
        builtins.toJSON {Path = widevineDir;};
    };
  };
}
