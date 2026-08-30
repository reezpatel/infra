# Package set, docker, udev rules and nix-ld for divine.
{
  config,
  pkgs,
  ...
}: let
  ndrop = pkgs.writeShellApplication {
    name = "ndrop";
    runtimeInputs = with pkgs; [
      bash
      getopt
      iputils
      jq
      libnotify
      niri
    ];
    text = ''
      exec ${pkgs.bash}/bin/bash ${
        pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Schweber/ndrop/main/ndrop";
          sha256 = "0s49hsyxfwcsyliad1nihlqaljsa3jbqsajj2hasmivmmmm18cdp";
        }
      } "$@"
    '';
  };

  freedownloadmanager = pkgs.stdenv.mkDerivation {
    pname = "freedownloadmanager";
    version = "latest";

    src = pkgs.fetchurl {
      url = "https://dn3.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
      sha256 = "0a84dpjh1w1da9gc58zv8lny3fdbjmvibcmiha2lws2900542zxg";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeWrapper
    ];

    buildInputs = with pkgs; [
      alsa-lib
      atk
      cairo
      cups
      dbus
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      harfbuzz
      libGL
      libdrm
      libpulseaudio
      libxkbcommon
      nss
      openssl
      pango
      wayland
      libice
      libsm
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      xcbutil
      xcbutilcursor
      xcbutilimage
      xcbutilrenderutil
      xcbutilwm
      zlib
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt $out/bin $out/share/applications $out/share/pixmaps
      cp -R opt/freedownloadmanager $out/opt/
      cp usr/share/applications/freedownloadmanager.desktop $out/share/applications/
      cp opt/freedownloadmanager/icon.png $out/share/pixmaps/freedownloadmanager.png

      rm -f $out/opt/freedownloadmanager/plugins/imageformats/libqtiff.so
      rm -f $out/opt/freedownloadmanager/plugins/sqldrivers/libqsql{ibase,mimer,mysql,oci,odbc,psql}.so

      substituteInPlace $out/share/applications/freedownloadmanager.desktop \
        --replace-fail "Exec=/opt/freedownloadmanager/fdm" "Exec=fdm" \
        --replace-fail "Icon=/opt/freedownloadmanager/icon.png" "Icon=freedownloadmanager"

      makeWrapper $out/opt/freedownloadmanager/fdm $out/bin/fdm \
        --set QT_QPA_PLATFORM wayland \
        --prefix LD_LIBRARY_PATH : $out/opt/freedownloadmanager/lib

      runHook postInstall
    '';

    meta = {
      description = "Free Download Manager packaged from the official Linux deb";
      homepage = "https://www.freedownloadmanager.org/";
      platforms = ["x86_64-linux"];
    };
  };
in {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  services.printing.drivers = with pkgs; [
    brgenml1lpr
    brgenml1cupswrapper
  ];

  users.users.${config.username}.extraGroups = [
    "docker"
    "video"
    "dialout"
    "tty"
    "lp"
    "scanner"
  ];

  services.udev.extraRules = ''
    # sigrok fx2lafw logic analyzers (e.g. Saleae clones)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", MODE="0660", GROUP="users"
    ATTRS{idVendor}=="0925", ATTRS{idProduct}=="3881", MODE="0660", GROUP="users"

    # Seeed Studio devices (all XIAO boards, CMSIS-DAP debuggers)
    ACTION=="add|change", SUBSYSTEM=="usb",    ATTR{idVendor}=="2886", MODE="0660", GROUP="dialout", TAG+="uaccess"
    ACTION=="add|change", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2886", MODE="0660", GROUP="dialout", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    mergerfs
    mdadm
    lsof
    uv
    gcc
    gnumake
    git
    pkg-config
    stdenv.cc.cc.lib
    ffmpeg
    docker-compose
    xwayland-satellite
    swaybg
    ndrop
    walker
    elephant
    nemo
    libnotify
    playerctl
    brightnessctl
    wl-clipboard
    grim
    slurp
    bolt
    awscli2
    arduino-ide
    beekeeper-studio
    freedownloadmanager
    basedpyright
    ruff

    sftool
    pulseview
    sigrok-firmware-fx2lafw

    nrfutil
    nrfconnect-bluetooth-low-energy

    terraform
  ];

  # Enable nix-ld for running dynamically linked binaries (like Zed's codex-acp)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      libgcc
    ];
  };
}
