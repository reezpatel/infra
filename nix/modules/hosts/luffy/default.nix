# luffy — MacBook Pro (work): full mac workstation with autossh DB tunnels.
{
  inputs,
  self,
  ...
}: {
  flake.darwinConfigurations.luffy = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";

    modules = with self.modules.darwin; [
      # Aspects
      mac
      home

      # Host-specific
      ./_auto-ssh.nix

      # Identity
      (
        {
          config,
          pkgs,
          ...
        }: {
          hostname = "luffy";

          environment.variables = {
            OLLAMA_HOST = "192.168.2.5";
            DOCKER_HOST = "tcp://192.168.2.5:2375";
            OPENCODE_DISABLE_CLAUDE_CODE = "1";
            # TODO: Move to files
            OPENCODE_TUI_CONFIG = "/Users/reezpatel/.config/opencode/tui.json";
          };

          environment.systemPackages = with pkgs; [
            claude-code
            awscli2
            doctl
            terraform
            pm2
            autossh
            gemini-cli
            codex
            gh
            git-wt
            igraph

            codecov-cli
          ];

          homebrew.masApps = {};
          homebrew.brews = [];
          homebrew.casks = [
            "1password"
            "edouard-claude/tap/snip"
            "alt-tab"
            "bartender"
            "beekeeper-studio"
            "bruno"
            "free-download-manager"
            "ghostty"
            "google-chrome"
            "insomnia"
            "lens"
            "meetingbar"
            "obsidian"
            "parsec"
            "postman"
            "raycast"
            "rectangle-pro"
            "slack"
            "visual-studio-code"
            "vlc"
            "whatsapp"
            "zed"
            "zoom"
            "proton-pass"
            "ticktick"
            "leapp"
          ];

          home-manager.users.${config.username} = {...}: {
            age.identityPaths = ["/Users/reezpatel/.ssh/id_ed25519"];
            age.secrets.private-func.file = ../../../../secerts/private-func.age;

            imports = with self.modules.homeManager; [
              shell
              nvim
              runtimes
              devops
              ollama
              ghostty
              zed
              opencode
            ];
          };
        }
      )
    ];
  };
}
