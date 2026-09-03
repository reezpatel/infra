{...}: {
  flake.modules.nixos.leapp = {
    lib,
    pkgs,
    ...
  }: let
    pname = "leapp";
    version = "0.26.1";
    src = pkgs.fetchurl {
      url = "https://asset.noovolari.com/${version}/Leapp-${version}.AppImage";
      hash = "sha256-DX6Fop2C0HWBXOXiozQdrlbO+a7ll7W0sBB+HuDZiSw=";
    };
    appimageContents = pkgs.appimageTools.extract {
      inherit pname src version;
    };
    leapp = pkgs.appimageTools.wrapType2 {
      inherit pname src version;

      extraPkgs = pkgs:
        with pkgs; [
          libsecret
          gtk3
          nss
          at-spi2-atk
          at-spi2-core
          cups
          libdrm
          mesa
          libxkbcommon
          alsa-lib
        ];

      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/leapp.desktop \
          $out/share/applications/leapp.desktop
        cp -r ${appimageContents}/usr/share/icons $out/share/
        substituteInPlace $out/share/applications/leapp.desktop \
          --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=leapp %U" \
          --replace-fail "Icon=/usr/share/icons/hicolor/256x256/apps/leapp.png" "Icon=leapp"
      '';

      meta = {
        description = "Cloud credentials manager";
        homepage = "https://www.leapp.cloud/";
        license = lib.licenses.mpl20;
        mainProgram = "leapp";
        platforms = ["x86_64-linux"];
      };
    };
  in {
    environment.systemPackages = [
      leapp
      pkgs.gnome-keyring
    ];
  };
}
