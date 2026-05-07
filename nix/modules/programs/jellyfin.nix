{ ... }:
let
  mkJellyfinExporter =
    pkgs:
    pkgs.stdenv.mkDerivation rec {
      pname = "jellyfin_exporter";
      version = "1.5.0";

      src = pkgs.fetchurl {
        url = "https://github.com/rebelcore/jellyfin_exporter/releases/download/v${version}/jellyfin_exporter-${version}.${
          if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then "linux-arm64" else "linux-amd64"
        }.tar.gz";
        hash =
          if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
            "sha256-NRAh0Hf7Lc19WMWYswM42CtYpUv89mwGHpqzq7Yx/0Q="
          else
            "sha256-ROWSEHBfwWTJx5g16gdD7bmDLuLEwXCwQT8DOVdgRFk=";
      };

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src -C $out/bin --strip-components=1
        chmod +x $out/bin/jellyfin_exporter
      '';

      meta.mainProgram = "jellyfin_exporter";
    };
in
{
  moduleRegistry.nixos.jellyfin =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      exporter = mkJellyfinExporter pkgs;
    in
    {
      users.users.${config.username}.extraGroups = [
        "video"
        "render"
      ];

      age.secrets.jellyfin-api-key = {
        file = ../../../secerts/jellyfin-api-key.age;
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d /mnt/mergefs/programs/jellyfin/config 0700 ${config.username} users -"
        "d /mnt/mergefs/programs/jellyfin/cache  0700 ${config.username} users -"
        "d /mnt/mergefs/programs/jellyfin/log    0700 ${config.username} users -"
      ];

      systemd.services.jellyfin = {
        after = [ "mnt-mergefs.mount" ];
        requires = [ "mnt-mergefs.mount" ];
      };

      systemd.services.jellyfin-exporter = {
        description = "Jellyfin Prometheus Exporter";
        wantedBy = [ "multi-user.target" ];
        after = [ "jellyfin.service" ];
        wants = [ "jellyfin.service" ];
        script = ''
          exec ${exporter}/bin/jellyfin_exporter \
            --jellyfin.address=http://127.0.0.1:8096 \
            --jellyfin.token="$(cat ${config.age.secrets.jellyfin-api-key.path})"
        '';
        serviceConfig = {
          DynamicUser = true;
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      networking.firewall.allowedTCPPorts = [ 9594 ];

      services.jellyfin = {
        enable = true;
        dataDir = "/mnt/mergefs/programs/jellyfin";
        cacheDir = "/mnt/mergefs/programs/jellyfin/cache";
        openFirewall = true;
        user = config.username;

        hardwareAcceleration = {
          enable = true;
          type = "nvenc";
          device = "/dev/nvidia0";
        };

        transcoding = {
          enableHardwareEncoding = true;
          hardwareDecodingCodecs = {
            h264 = true;
            hevc = true;
            hevc10bit = true;
            vp9 = true;
            av1 = true;
          };
          hardwareEncodingCodecs = {
            hevc = true;
            av1 = true;
          };
        };
      };
    };
}
