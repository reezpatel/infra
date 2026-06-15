{...}: {
  moduleRegistry.nixos.helium = {
    lib,
    pkgs,
    ...
  }: let
    sources = {
      x86_64-linux = {
        debArch = "amd64";
        hash = "sha256-HwO3aM0E1u0V2kHcQSBsqHmRENkPfVEeBZWJdPZ/SKk=";
      };
      aarch64-linux = {
        debArch = "arm64";
        hash = "sha256-kVJqHPd0tNihoMKzpstGvFW2fbsL9Uc0IjZkD45yuhI=";
      };
    };
    source = sources.${pkgs.stdenv.hostPlatform.system} or null;
    isSupported = source != null;
    helium = pkgs.stdenv.mkDerivation rec {
      pname = "helium";
      version = "0.13.3.1";

      src = pkgs.fetchurl {
        url = "https://pkg.helium.computer/deb/pool/main/h/helium-bin/helium-bin_${version}-1_${source.debArch}.deb";
        inherit (source) hash;
      };

      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.makeWrapper
      ];

      buildInputs = with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        expat
        fontconfig
        freetype
        glib
        harfbuzz
        libdrm
        libgbm
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxi
        libxrandr
        libxrender
        libxshmfence
        libglvnd
        libxkbcommon
        mesa
        nspr
        nss
        pango
        systemd
        stdenv.cc.cc.lib
        vulkan-loader
        zlib
      ];

      autoPatchelfIgnoreMissingDeps = [
        "libQt5Core.so.5"
        "libQt5Gui.so.5"
        "libQt5Widgets.so.5"
        "libQt6Core.so.6"
        "libQt6Gui.so.6"
        "libQt6Widgets.so.6"
      ];

      unpackPhase = ''
        runHook preUnpack
        ar x "$src"
        tar -xf data.tar.*
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/bin" "$out/opt" "$out/share"
        cp -r opt/helium "$out/opt/"
        cp -r usr/share/applications "$out/share/"
        cp -r usr/share/icons "$out/share/"
        cp -r usr/share/metainfo "$out/share/"

        makeWrapper "$out/opt/helium/helium-wrapper" "$out/bin/helium" \
          --prefix PATH : ${lib.makeBinPath [pkgs.xdg-utils]}

        runHook postInstall
      '';

      meta = {
        description = "Private, fast, and honest web browser";
        homepage = "https://github.com/imputnet/helium-linux";
        license = lib.licenses.gpl3Only;
        mainProgram = "helium";
        platforms = builtins.attrNames sources;
      };
    };
  in {
    warnings = lib.optional (!isSupported) ''
      Skipping Helium: no packaged source is defined for ${pkgs.stdenv.hostPlatform.system}.
    '';

    environment.systemPackages = lib.optionals isSupported [
      helium
    ];
  };
}
