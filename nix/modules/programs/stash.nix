{...}: let
  mkStashBin = pkgs:
    pkgs.stdenv.mkDerivation rec {
      pname = "stash";
      version = "0.31.1";

      src = pkgs.fetchurl {
        url = "https://github.com/stashapp/stash/releases/download/v${version}/stash-linux";
        hash = "sha256-X3E5Grx866/VuS97MlCWJzDIvj5/EvI/2YAph4slaMA=";
      };

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/stash
        chmod +x $out/bin/stash
      '';

      meta = {
        description = "Organizer for adult media";
        homepage = "https://github.com/stashapp/stash";
        license = pkgs.lib.licenses.agpl3Only;
        mainProgram = "stash";
        platforms = pkgs.lib.platforms.linux;
      };

      passthru.updateScript = [
        "nix-update"
        "--flake"
        "--system"
        "x86_64-linux"
        "--version-regex"
        "v([0-9].*)"
        "stash-bin"
      ];
    };
in {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      stash-bin = mkStashBin pkgs;
    };
  };

  moduleRegistry.nixos.stash = {
    config,
    pkgs,
    lib,
    ...
  }: let
    ffmpegPackage = pkgs.ffmpeg-full;

    ffmpeg-cuda = pkgs.writeShellScriptBin "ffmpeg" ''
      for arg in "$@"; do
        case "$arg" in
          *.jpg|*.jpeg|*.png|*.gif|*.webp)
            exec ${ffmpegPackage}/bin/ffmpeg "$@"
            ;;
        esac
      done
      exec ${ffmpegPackage}/bin/ffmpeg -hwaccel cuda "$@"
    '';
    stash-bin = mkStashBin pkgs;
  in {
    options.stash.forceCuda = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force all Stash ffmpeg executions to use CUDA hwaccel via a wrapper binary.";
    };

    config = {
      users.groups.media = {};
      users.users.stash.extraGroups = ["video" "render" "media"];
      users.users.${config.username}.extraGroups = ["media"];

      age.secrets.stash-jwt-key.file = ../../../secerts/stash-jwt-key.age;
      age.secrets.stash-session-key.file = ../../../secerts/stash-session-key.age;
      age.secrets.stash-password.file = ../../../secerts/stash-password.age;

      systemd.tmpfiles.rules = [
        "L /data - - - - /mnt/mergefs/media/others/private/adult"
        "d /mnt/mergefs/programs/stash/config    0750 stash media -"
        "d /mnt/mergefs/programs/stash/generated 0750 stash media -"
        "d /mnt/mergefs/programs/stash/cache     0750 stash media -"
        "d /mnt/mergefs/programs/stash/blob      0750 stash media -"
        "d /mnt/mergefs/programs/stash/plugins   0750 stash media -"
        "d /mnt/mergefs/programs/stash/scrapers  0750 stash media -"
        "d /mnt/mergefs/programs/stash/metadata  0750 stash media -"
        "d /mnt/mergefs/media/others/private/adult 2775 ${config.username} media -"
      ];

      systemd.services.stash.path = lib.optional config.stash.forceCuda ffmpeg-cuda;

      systemd.services.stash.preStart = lib.mkAfter ''
        config=/mnt/mergefs/programs/stash/config/config.yml
        tmp=$(mktemp "$config.XXXXXX")
        ${pkgs.gnused}/bin/sed \
          -e 's|^ffmpeg_path:.*|ffmpeg_path: ${
          if config.stash.forceCuda
          then "${ffmpeg-cuda}/bin/ffmpeg"
          else "${ffmpegPackage}/bin/ffmpeg"
        }|' \
          -e 's|^ffprobe_path:.*|ffprobe_path: ${ffmpegPackage}/bin/ffprobe|' \
          -e '/^ffmpeg:/,/^[^[:space:]]/ s|^    hardware_acceleration:.*|    hardware_acceleration: false|' \
          "$config" > "$tmp"
        mv "$tmp" "$config"
      '';

      systemd.services.stash.environment =
        {
          STASH_METADATA = "/mnt/mergefs/programs/stash/metadata";
        }
        // lib.optionalAttrs config.stash.forceCuda {
          LD_LIBRARY_PATH = lib.makeLibraryPath [
            pkgs.cudaPackages_13_0.cudatoolkit
            pkgs.cudaPackages_13_0.cuda_nvcc
            "/run/opengl-driver/lib"
          ];
        };

      systemd.services.stash.serviceConfig = {
        BindReadOnlyPaths = lib.mkForce [];
        BindPaths = ["/mnt/mergefs/media/others/private/adult"];
      };

      services.stash = {
        enable = true;
        package = stash-bin;
        dataDir = "/mnt/mergefs/programs/stash/config";
        user = "stash";

        jwtSecretKeyFile = config.age.secrets.stash-jwt-key.path;
        sessionStoreKeyFile = config.age.secrets.stash-session-key.path;
        username = "admin";
        passwordFile = config.age.secrets.stash-password.path;
        mutablePlugins = true;
        mutableScrapers = true;

        settings = {
          host = "0.0.0.0";
          port = 9999;

          stash = [
            {
              path = "/mnt/mergefs/media/others/private/adult";
              excludevideo = false;
              excludeimage = false;
            }
          ];

          ffmpeg_path =
            if config.stash.forceCuda
            then "${ffmpeg-cuda}/bin/ffmpeg"
            else "${ffmpegPackage}/bin/ffmpeg";
          ffprobe_path = "${ffmpegPackage}/bin/ffprobe";

          ffmpeg = {
            hardware_acceleration = false;
          };

          generated = "/mnt/mergefs/programs/stash/generated";
          cache = "/mnt/mergefs/programs/stash/cache";
          blobs_path = "/mnt/mergefs/programs/stash/blob";
          plugins_path = "/mnt/mergefs/programs/stash/plugins";
          scrapers_path = "/mnt/mergefs/programs/stash/scrapers";
        };
      };
    };
  };
}
