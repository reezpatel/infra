{...}: {
  moduleRegistry.nixos.stash = {
    config,
    pkgs,
    lib,
    ...
  }: let
    ffmpegPackage = pkgs.ffmpeg-full;

    ffmpeg-cuda = pkgs.writeShellScriptBin "ffmpeg" ''
      exec ${ffmpegPackage}/bin/ffmpeg -hwaccel cuda -hwaccel_output_format cuda "$@"
    '';

    stash-bin = pkgs.stdenv.mkDerivation {
      pname = "stash";
      version = "0.31.0";

      src = pkgs.fetchurl {
        url = "https://github.com/stashapp/stash/releases/download/v0.31.0/stash-linux";
        hash = "sha256-KPsvA07+HGAsskZ1y5Q1Mcts8t3eSgTYFtl1oOD/w+I=";
      };

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/stash
        chmod +x $out/bin/stash
      '';
    };
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
        "d /mnt/mergefs/programs/stash/config    0750 stash stash -"
        "d /mnt/mergefs/programs/stash/generated 0750 stash stash -"
        "d /mnt/mergefs/programs/stash/cache     0750 stash stash -"
        "d /mnt/mergefs/programs/stash/blob      0750 stash stash -"
        "d /mnt/mergefs/programs/stash/plugins   0750 stash stash -"
        "d /mnt/mergefs/programs/stash/scrapers  0750 stash stash -"
        "d /mnt/mergefs/programs/stash/metadata  0750 stash stash -"
        "d /mnt/mergefs/media/others/private/adult 2775 ${config.username} media -"
      ];

      systemd.services.stash.path = lib.optional config.stash.forceCuda ffmpeg-cuda;

      systemd.services.stash.environment =
        {
          STASH_METADATA = "/mnt/mergefs/programs/stash/metadata";
        }
        // lib.optionalAttrs config.stash.forceCuda {
          LD_LIBRARY_PATH = lib.makeLibraryPath [
            pkgs.cudaPackages.cudatoolkit
            pkgs.cudaPackages.cuda_nvcc
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
