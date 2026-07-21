{...}: {
  flake.homeModules.openclaw = {
    config,
    pkgs,
    ...
  }: let
    openclaw = pkgs.openclaw.overrideAttrs (old: {
      pnpmDepsHash = "sha256-fCjggRmkpNGj7m5kc2MwA+lEGErAhMS9rFDTx7Uubiw=";
      meta =
        old.meta
        // {
          knownVulnerabilities = [];
        };
    });
    stateDir = "${config.home.homeDirectory}/.openclaw";
  in {
    home.packages = [
      openclaw
    ];

    home.file.".openclaw/openclaw.json".source = ../../../dotfiles/openclaw/openclaw.json;

    systemd.user.services.openclaw = {
      Unit = {
        Description = "OpenClaw Gateway";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        ExecStart = "${openclaw}/bin/openclaw gateway run --port 18789";
        Restart = "always";
        RestartSec = "5s";
        TimeoutStopSec = "30s";
        TimeoutStartSec = "30s";
        SuccessExitStatus = "0 143";
        KillMode = "control-group";
        WorkingDirectory = config.home.homeDirectory;
        Environment = [
          "HOME=${config.home.homeDirectory}"
          "OPENCLAW_NIX_MODE=1"
          "OPENCLAW_STATE_DIR=${stateDir}"
          "OPENCLAW_CONFIG_PATH=${stateDir}/openclaw.json"
        ];
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
